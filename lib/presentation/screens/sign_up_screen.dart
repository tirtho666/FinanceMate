import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_wave_header.dart';
import '../widgets/sign_up_form.dart';

/// Create-account screen matching `assets/signup_ui.png`.
///
/// Layout only: registration is handled by [SignUpForm], which talks to
/// `AuthProvider` (REST signup, JWT storage, and App Lock hashing).
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key, required this.onSwitchToLogin});

  final VoidCallback onSwitchToLogin;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                              'Create Account',
                              style: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppPalette.authNavy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign up to get started',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppPalette.authSubtitle,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SignUpForm(onSwitchToLogin: onSwitchToLogin),
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
