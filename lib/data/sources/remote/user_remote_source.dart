import 'dart:async';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/currency_preferences.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../domain/failures/data_failure.dart';
import '../../models/user_model.dart';

/// User/profile data source backed by the FinanceMate Node.js + PostgreSQL API.
///
/// [ApiClient] attaches the persisted `Authorization: Bearer <token>` header,
/// so the profile endpoints always resolve to the signed-in user without the
/// data source having to know the id.
class UserRemoteSource {
  UserRemoteSource(this._api, this._storage, this._currencyPreferences);

  static const String _profilePath = '/api/users/profile';

  final ApiClient _api;
  final SecureStorageService _storage;
  final CurrencyPreferences _currencyPreferences;
  final StreamController<UserModel?> _profileEvents =
      StreamController<UserModel?>.broadcast();

  UserModel? _current;
  bool _restored = false;

  /// Emits the cached profile first, then every later change (profile update,
  /// currency change, …) so watchers such as `HomeProvider` stay in sync.
  Stream<UserModel?> watchCurrentUser() async* {
    await _ensureRestored();
    yield _current ?? await _fetchProfile();
    yield* _profileEvents.stream;
  }

  Future<UserModel?> getCurrentUser() async {
    await _ensureRestored();
    return _fetchProfile();
  }

  /// Returns the server profile, seeding a local one when the backend has no
  /// record yet (for example right after a very first sign up).
  Future<UserModel> ensureCurrentUserProfile({String currency = 'BDT'}) async {
    await _ensureRestored();
    final existing = _current ?? await _fetchProfile();
    if (existing != null) return existing;

    final seeded = UserModel(
      uid: _storage.userId ?? _storage.email ?? '',
      balance: 0,
      totalIncome: 0,
      totalExpense: 0,
      currency: _currencyPreferences.code ?? currency,
      fullName: _storage.displayName,
    );
    _current = seeded;
    return seeded;
  }

  Future<void> updateProfile({String? fullName, String? phoneNumber}) async {
    if (fullName == null && phoneNumber == null) return;
    await _ensureRestored();

    final response = await _putProfile(<String, dynamic>{
      'full_name': ?fullName,
      'fullName': ?fullName,
      'name': ?fullName,
      'phone_number': ?phoneNumber,
      'phoneNumber': ?phoneNumber,
    });

    // Keep the persisted session details aligned with the new profile.
    await _storage.updateSessionUser(
      email: _firstString(_profileJson(response), const ['email']),
      displayName: fullName,
    );

    final updated = _tryModelFrom(response) ??
        (_current ??
                UserModel(
                  uid: _storage.userId ?? '',
                  balance: 0,
                  totalIncome: 0,
                  totalExpense: 0,
                  currency: _currencyPreferences.code ?? 'BDT',
                ))
            .copyWith(fullName: fullName, phoneNumber: phoneNumber);
    _publishCurrent(updated);
  }

  /// Persists the choice on the device and syncs it to the profile endpoint.
  /// The local write is what actually keeps the symbol correct across restarts,
  /// so the server write stays best effort: a backend that does not know the
  /// field yet must not block the user's choice.
  Future<void> updateCurrency(String currency) async {
    await _ensureRestored();
    final normalized = currency.trim().toUpperCase();
    await _currencyPreferences.save(normalized);
    try {
      final response = await _putProfile(<String, dynamic>{
        'currency': normalized,
      });
      _publishCurrent(
        _tryModelFrom(response)?.copyWith(currency: normalized) ??
            _withCurrency(normalized),
      );
    } on ApiException {
      _publishCurrent(_withCurrency(normalized));
    }
  }

  Future<void> dispose() => _profileEvents.close();

  Future<UserModel?> _fetchProfile() async {
    if (!_storage.hasSession) return null;
    try {
      final response = await _api.get(_profilePath);
      var model = _tryModelFrom(response) ?? UserModel.fromJson(response);
      if (model.uid.isEmpty) {
        model = model.copyWith(uid: _storage.userId ?? '');
      }
      model = await _syncCurrencyPreference(model);
      _current = model;
      return model;
    } on ApiException catch (error) {
      if (error.isMissingEndpoint) return _current;
      throw DataFailure(error.message);
    }
  }

  /// The currency picked on this device wins over whatever the profile carries
  /// (the server field is best effort); on the very first load the server value
  /// is remembered so a fresh install adopts it.
  Future<UserModel> _syncCurrencyPreference(UserModel model) async {
    if (_currencyPreferences.hasSelection) {
      return model.copyWith(currency: _currencyPreferences.code);
    }
    await _currencyPreferences.save(model.currency);
    return model;
  }

  /// `PUT /api/users/profile`, falling back to `PATCH` when the backend does
  /// not expose the update verb.
  Future<Map<String, dynamic>> _putProfile(Map<String, dynamic> body) async {
    try {
      return await _api.put(_profilePath, body: body);
    } on ApiException catch (error) {
      if (!error.isMissingEndpoint) rethrow;
      return _api.patch(_profilePath, body: body);
    }
  }

  UserModel _withCurrency(String currency) {
    final base = _current ??
        UserModel(
          uid: _storage.userId ?? '',
          balance: 0,
          totalIncome: 0,
          totalExpense: 0,
          currency: currency,
        );
    return base.copyWith(currency: currency);
  }

  void _publishCurrent(UserModel? model) {
    _current = model;
    if (_profileEvents.isClosed) return;
    _profileEvents.add(model);
  }

  Future<void> _ensureRestored() async {
    if (_restored) return;
    await Future.wait<void>([
      _storage.restore(),
      _currencyPreferences.load(),
    ]);
    _restored = true;
  }

  /// Finds the profile object inside the response (`user`, `data`, `profile`,
  /// …), falling back to the root payload.
  Map<String, dynamic> _profileJson(Map<String, dynamic> json) {
    for (final key in const ['user', 'data', 'profile', 'account', 'result']) {
      final nested = json[key];
      if (nested is Map && _looksLikeProfile(nested)) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return json;
  }

  UserModel? _tryModelFrom(Map<String, dynamic> json) {
    final candidate = _profileJson(json);
    if (!_looksLikeProfile(candidate)) return null;
    final model = UserModel.fromJson(candidate);
    return model.uid.isEmpty ? model.copyWith(uid: _storage.userId ?? '') : model;
  }

  bool _looksLikeProfile(Map<dynamic, dynamic> json) {
    return json.containsKey('id') ||
        json.containsKey('_id') ||
        json.containsKey('userId') ||
        json.containsKey('user_id') ||
        json.containsKey('uid') ||
        json.containsKey('email');
  }

  String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
