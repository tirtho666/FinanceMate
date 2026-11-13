import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfSignedIn());
  }

  void _redirectIfSignedIn() {
    if (!mounted) return;
    if (context.read<AuthProvider>().isAuthenticated) {
      // Ekhane aage AppRoutes.main chilo, seta change kore AppRoutes.lock kora holo
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.lock,
        (route) => false,
      );
    }
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
                            onSwitchToSignUp: () => _scrollTo(_signUpKey),
                          ),
                        ),
                        const SizedBox(height: 32),
                        KeyedSubtree(
                          key: _signUpKey,
                          child: SignUpForm(
                            onSwitchToLogin: () => _scrollTo(_loginKey),
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