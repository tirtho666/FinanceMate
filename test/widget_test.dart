import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:financemate/app.dart';
import 'package:financemate/domain/entities/app_user.dart';
import 'package:financemate/domain/repositories/auth_repository.dart';
import 'package:financemate/domain/usecases/sign_in_with_email.dart';
import 'package:financemate/domain/usecases/sign_out.dart';
import 'package:financemate/domain/usecases/sign_up_with_email.dart';
import 'package:financemate/domain/usecases/watch_auth_state.dart';
import 'package:financemate/presentation/providers/auth_provider.dart';
import 'package:financemate/presentation/screens/auth_screen.dart';

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
  testWidgets('Auth screen shows logo and login/sign up forms', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(
          signInWithEmail: SignInWithEmail(repository),
          signUpWithEmail: SignUpWithEmail(repository),
          signOutUseCase: SignOut(repository),
          watchAuthState: WatchAuthState(repository),
        ),
        child: const FinanceMateApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('SIGN UP'), findsOneWidget);
    expect(find.text('Log In'), findsWidgets);
    expect(find.text('Sign Up'), findsWidgets);
  });
}
