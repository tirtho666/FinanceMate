import '../entities/user_profile.dart';

abstract class UserRepository {
  Stream<UserProfile?> watchCurrentUser();

  Future<UserProfile?> getCurrentUser();

  Future<UserProfile> ensureCurrentUserProfile({String currency = 'BDT'});

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
  });

  Future<void> updateCurrency(String currency);
}
