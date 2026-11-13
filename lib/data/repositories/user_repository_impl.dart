import '../../domain/entities/user_profile.dart';
import '../../domain/failures/data_failure.dart';
import '../../domain/repositories/user_repository.dart';
import '../sources/remote/user_remote_source.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteSource);

  final UserRemoteSource _remoteSource;

  @override
  Stream<UserProfile?> watchCurrentUser() {
    return _remoteSource.watchCurrentUser().map((user) => user?.toEntity());
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    try {
      final user = await _remoteSource.getCurrentUser();
      return user?.toEntity();
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Could not load your profile.');
    }
  }

  @override
  Future<UserProfile> ensureCurrentUserProfile({
    String currency = 'BDT',
  }) async {
    try {
      final user = await _remoteSource.ensureCurrentUserProfile(
        currency: currency,
      );
      return user.toEntity();
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Could not create your profile.');
    }
  }

  @override
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      await _remoteSource.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Could not update your profile.');
    }
  }

  @override
  Future<void> updateCurrency(String currency) async {
    try {
      await _remoteSource.updateCurrency(currency);
    } on DataFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure('Could not update your currency.');
    }
  }
}
