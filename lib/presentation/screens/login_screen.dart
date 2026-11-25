import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_wave_header.dart';
import '../widgets/login_form.dart';

/// Sign-in screen matching `assets/login_ui.png`.
///
/// The widget is layout-only: credentials are handled by [LoginForm], which
/// talks to `AuthProvider` (REST login + JWT storage + App Lock hashing).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onSwitchToSignUp});

  final VoidCallback onSwitchToSignUp;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The wave header sits behind the status bar, so its icons stay light.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthWaveHeader(topInset: topInset),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: AuthLogo()),
                            const SizedBox(height: 18),
                            Text(
                              'Welcome Back',
                              style: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppPalette.authNavy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to your account',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppPalette.authSubtitle,
                              ),
                            ),
                            const SizedBox(height: 20),
                            LoginForm(onSwitchToSignUp: onSwitchToSignUp),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
