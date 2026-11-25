import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:financemate/app.dart';
import 'package:financemate/core/storage/secure_storage_service.dart';
import 'package:financemate/data/repositories/app_lock_repository_impl.dart';
import 'package:financemate/data/sources/local/app_lock_local_source.dart';
import 'package:financemate/domain/entities/app_user.dart';
import 'package:financemate/domain/repositories/auth_repository.dart';
import 'package:financemate/domain/usecases/set_app_lock_password.dart';
import 'package:financemate/domain/usecases/sign_in_with_email.dart';
import 'package:financemate/domain/usecases/sign_out.dart';
import 'package:financemate/domain/usecases/sign_up_with_email.dart';
import 'package:financemate/domain/usecases/verify_app_lock_password.dart';
import 'package:financemate/domain/usecases/watch_auth_state.dart';
import 'package:financemate/presentation/providers/app_lock_provider.dart';
import 'package:financemate/presentation/providers/auth_provider.dart';
import 'package:financemate/presentation/screens/auth_screen.dart';
import 'package:financemate/presentation/screens/login_screen.dart';
import 'package:financemate/presentation/screens/sign_up_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> watchAuthState() => Stream<AppUser?>.value(null);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateDisplayName(String fullName) async {}

  @override
  Future<void> updateEmail(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> reloadUser() async {}
}

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('Auth screen shows the login design and the sign up link', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository();
    final secureStorage = SecureStorageService();
    final appLockRepository = AppLockRepositoryImpl(
      AppLockLocalSource(secureStorage),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SecureStorageService>.value(value: secureStorage),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              signInWithEmail: SignInWithEmail(repository),
              signUpWithEmail: SignUpWithEmail(repository),
              signOutUseCase: SignOut(repository),
              setAppLockPassword: SetAppLockPassword(appLockRepository),
              watchAuthState: WatchAuthState(repository),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AppLockProvider(
              setPasswordUseCase: SetAppLockPassword(appLockRepository),
              verifyPasswordUseCase: VerifyAppLockPassword(appLockRepository),
              repository: appLockRepository,
            ),
          ),
        ],
        child: const FinanceMateApp(),
      ),
    );

    // Splash screen restores the session, then routes to the auth screen.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.textContaining('Sign Up'), findsOneWidget);

    final signUpLink = find.textContaining('Sign Up');
    await tester.ensureVisible(signUpLink);
    await tester.pumpAndSettle();
    await tester.tap(signUpLink);
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign up to get started'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    final logInLink = find.text('Already have an account? Log In');
    await tester.ensureVisible(logInLink);
    await tester.pumpAndSettle();
    await tester.tap(logInLink);
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
