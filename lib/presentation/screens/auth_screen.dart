import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_routes.dart';
import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

/// Authentication entry point. Unauthenticated users land on [LoginScreen]
/// and can open [SignUpScreen] from the sign-up link.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfSignedIn());
  }

  void _redirectIfSignedIn() {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isAuthenticated) return;
    // Ekhane aage AppRoutes.main chilo, seta change kore App Lock thakle
    // AppRoutes.lock kora holo.
    final appLock = context.read<AppLockProvider>();
    Navigator.of(context).pushNamedAndRemoveUntil(
      appLock.isEnabled ? AppRoutes.lock : AppRoutes.main,
      (route) => false,
    );
  }

  void _openSignUp() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SignUpScreen(
            onSwitchToLogin: () => Navigator.of(context).pop(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginScreen(onSwitchToSignUp: _openSignUp);
  }
}
