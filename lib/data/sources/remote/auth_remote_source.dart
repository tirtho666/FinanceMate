import 'dart:async';
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../domain/failures/auth_failure.dart';
import '../../models/app_user_model.dart';

/// Auth data source backed by the FinanceMate Node.js + PostgreSQL REST API.
///
/// The returned JWT and user details are persisted through
/// [SecureStorageService]; a broadcast controller mirrors the auth state so the
/// presentation layer can keep watching a stream.
class AuthRemoteSource {
  AuthRemoteSource(this._api, this._storage);

  static const String _signUpPath = '/api/auth/signup';
  static const String _registerPath = '/api/auth/register';
  static const String _loginPath = '/api/auth/login';
  static const String _profilePath = '/api/auth/profile';
  static const String _changePasswordPath = '/api/users/change-password';

  final ApiClient _api;
  final SecureStorageService _storage;
  final StreamController<AppUserModel?> _authEvents =
      StreamController<AppUserModel?>.broadcast();

  bool _sessionRestored = false;

  Future<void> restoreSession() async {
    if (_sessionRestored) return;
    await _storage.restore();
    _sessionRestored = true;
  }

  Stream<AppUserModel?> watchUser() async* {
    await restoreSession();
    yield currentUser;
    yield* _authEvents.stream;
  }

  AppUserModel? get currentUser {
    if (!_storage.hasSession) return null;
    return AppUserModel(
      id: _storage.userId ?? '',
      email: _storage.email ?? '',
      displayName: _storage.displayName,
    );
  }

  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        _loginPath,
        body: {'email': email, 'password': password},
        attachToken: false,
      );
      return await _persistSession(response, fallbackEmail: email);
    } on ApiException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  Future<AppUserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName,
      'name': fullName,
      'fullName': fullName,
      'email': email,
      'password': password,
    };
    try {
      final response = await _api.post(
        _signUpPath,
        body: body,
        attachToken: false,
      );
      final token = _extractToken(response);
      if (token == null || token.isEmpty) {
        return await signIn(email: email, password: password);
      }
      return await _persistSession(
        response,
        fallbackEmail: email,
        fallbackDisplayName: fullName,
      );
    } on ApiException catch (error) {
      if (!error.isMissingEndpoint) throw AuthFailure(error.message);
      // The backend may expose the registration route under `/register`.
      try {
        final fallback = await _api.post(
          _registerPath,
          body: body,
          attachToken: false,
        );
        final token = _extractToken(fallback);
        if (token == null || token.isEmpty) {
          return await signIn(email: email, password: password);
        }
        return await _persistSession(
          fallback,
          fallbackEmail: email,
          fallbackDisplayName: fullName,
        );
      } on ApiException catch (fallbackError) {
        throw AuthFailure(fallbackError.message);
      }
    }
  }

  Future<void> signOut() async {
    await _storage.clearSession();
    _authEvents.add(null);
  }

  Future<void> updateDisplayName(String fullName) async {
    final user = _requireCurrentUser();
    final updated = user.copyWith(displayName: fullName.trim());
    try {
      await _api.patch(
        _profilePath,
        body: {
          'full_name': updated.displayName,
          'fullName': updated.displayName,
          'name': updated.displayName,
        },
      );
    } on ApiException catch (error) {
      if (!error.isMissingEndpoint) throw AuthFailure(error.message);
      // Profile sync is part of the Profile migration; keep the change locally.
    }
    await _storage.updateSessionUser(displayName: updated.displayName);
    _publish(updated);
  }

  Future<void> updateEmail(String email) async {
    final user = _requireCurrentUser();
    final updated = user.copyWith(email: email.trim());
    try {
      await _api.patch(_profilePath, body: {'email': updated.email});
    } on ApiException catch (error) {
      if (!error.isMissingEndpoint) throw AuthFailure(error.message);
      // Profile sync is part of the Profile migration; keep the change locally.
    }
    await _storage.updateSessionUser(email: updated.email);
    _publish(updated);
  }

  /// `POST /api/users/change-password`, falling back to `PUT` when the backend
  /// exposes the action under a different verb.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _requireCurrentUser();
    final body = <String, dynamic>{
      'current_password': currentPassword,
      'new_password': newPassword,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
    try {
      await _api.post(_changePasswordPath, body: body, attachToken: true);
    } on ApiException catch (error) {
      if (!error.isMissingEndpoint) throw AuthFailure(error.message);
      try {
        await _api.put(_changePasswordPath, body: body, attachToken: true);
      } on ApiException catch (fallbackError) {
        throw AuthFailure(fallbackError.message);
      }
    }
  }

  Future<void> reloadUser() async {
    await _storage.restore();
    _publish(currentUser);
  }

  Future<AppUserModel> _persistSession(
    Map<String, dynamic> response, {
    String? fallbackEmail,
    String? fallbackDisplayName,
  }) async {
    final token = _extractToken(response);
    if (token == null || token.isEmpty) {
      throw const AuthFailure(
        'The server did not return a session token. Please try again.',
      );
    }

    final jwtClaims = _decodeJwtPayload(token);
    final mergedJson = <String, dynamic>{
      ...jwtClaims,
      ..._extractUserJson(response),
    };
    final parsed = AppUserModel.fromJson(mergedJson);

    final resolvedEmail = parsed.email.isNotEmpty
        ? parsed.email
        : (fallbackEmail ?? '').trim();
    final resolvedId = parsed.id.isNotEmpty
        ? parsed.id
        : (jwtClaims['sub']?.toString() ?? resolvedEmail);
    final resolvedName =
        (parsed.displayName != null && parsed.displayName!.trim().isNotEmpty)
        ? parsed.displayName!.trim()
        : fallbackDisplayName?.trim();

    if (resolvedId.isEmpty && resolvedEmail.isEmpty) {
      throw const AuthFailure(
        'The server sent an unexpected response. Please try again.',
      );
    }

    final user = AppUserModel(
      id: resolvedId.isNotEmpty ? resolvedId : resolvedEmail,
      email: resolvedEmail,
      displayName: resolvedName,
    );

    await _storage.saveSession(
      token: token,
      userId: user.id,
      email: user.email,
      displayName: user.displayName,
    );
    _sessionRestored = true;
    _publish(user);
    return user;
  }

  AppUserModel _requireCurrentUser() {
    final user = currentUser;
    if (user == null) {
      throw const AuthFailure('You must be signed in.');
    }
    return user;
  }

  void _publish(AppUserModel? user) {
    if (_authEvents.isClosed) return;
    _authEvents.add(user);
  }

  /// Reads the JWT from any of the usual response shapes, including one level of
  /// nesting (`{data: {token: …}}`, `{session: {accessToken: …}}`, …).
  String? _extractToken(Map<String, dynamic> json) {
    for (final key in const [
      'token',
      'accessToken',
      'access_token',
      'jwt',
      'idToken',
      'authToken',
    ]) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
    }
    for (final key in const ['data', 'session', 'result', 'auth', 'user']) {
      final nested = json[key];
      if (nested is Map) {
        final token = _extractToken(Map<String, dynamic>.from(nested));
        if (token != null) return token;
      }
    }
    return null;
  }

  /// Finds the user object inside the response (`user`, `data`, `profile`, …),
  /// falling back to the root payload.
  Map<String, dynamic> _extractUserJson(Map<String, dynamic> json) {
    for (final key in const ['user', 'data', 'profile', 'account', 'result']) {
      final nested = json[key];
      if (nested is Map && _looksLikeUser(nested)) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return json;
  }

  bool _looksLikeUser(Map<dynamic, dynamic> json) {
    return json.containsKey('email') ||
        json.containsKey('id') ||
        json.containsKey('_id') ||
        json.containsKey('uid') ||
        json.containsKey('userId') ||
        json.containsKey('user_id');
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return const {};
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
    } catch (_) {
      // Ignore malformed/non-JWT tokens and rely on response/fallback fields.
    }
    return const {};
  }
}