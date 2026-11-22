import '../../domain/entities/app_user.dart';

/// Data-layer representation of the authenticated user returned by the REST API.
class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.email,
    this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: _readString(json, const ['id', '_id', 'userId', 'user_id', 'uid']) ?? '',
      email: _readString(json, const ['email', 'userEmail', 'user_email']) ?? '',
      displayName: _readString(json, const [
        'fullName',
        'full_name',
        'name',
        'displayName',
        'display_name',
        'username',
      ]),
    );
  }

  AppUserModel copyWith({String? email, String? displayName}) {
    return AppUserModel(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  AppUser toEntity() {
    return AppUser(id: id, email: email, displayName: displayName);
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return '$value';
    }
    return null;
  }
}
