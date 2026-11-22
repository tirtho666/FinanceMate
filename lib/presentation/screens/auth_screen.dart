import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_logo.dart';
import '../widgets/login_form.dart';
import '../widgets/sign_up_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _scrollController = ScrollController();
  final _loginKey = GlobalKey();
  final _signUpKey = GlobalKey();
  // Each form owns its validation through its own [FormState], so submitting
  // one never validates the other. The screen keeps the keys so that switching
  // forms can clear the form the user is leaving.
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

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

  /// Clears the form being left before scrolling to the other one, so the
  /// inactive form never keeps stale validation errors on screen.
  void _switchToSignUp() {
    _loginFormKey.currentState?.reset();
    _scrollTo(_signUpKey);
  }

  void _switchToLogin() {
    _signUpFormKey.currentState?.reset();
    _scrollTo(_loginKey);
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const AuthLogo(),
                        const SizedBox(height: 28),
                        KeyedSubtree(
                          key: _loginKey,
                          child: LoginForm(
                            formKey: _loginFormKey,
                            onSwitchToSignUp: _switchToSignUp,
                          ),
                        ),
                        const SizedBox(height: 32),
                        KeyedSubtree(
                          key: _signUpKey,
                          child: SignUpForm(
                            formKey: _signUpFormKey,
                            onSwitchToLogin: _switchToLogin,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}