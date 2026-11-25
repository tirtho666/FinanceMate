import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../providers/auth_provider.dart';
import 'auth_text_field.dart';
import 'auth_validators.dart';

/// Name, email, and password form used by the sign-up screen.
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key, required this.onSwitchToLogin});

  final VoidCallback onSwitchToLogin;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<AuthProvider>().signUp(
      context: context,
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final textTheme = context.textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _nameController,
            hintText: 'Full Name',
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            enabled: !auth.isLoading,
            validator: AuthValidators.fullName,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _emailController,
            hintText: 'Email Address',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !auth.isLoading,
            validator: AuthValidators.email,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            textInputAction: TextInputAction.done,
            enabled: !auth.isLoading,
            validator: AuthValidators.password,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppPalette.authNavy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppPalette.authNavy.withValues(
                  alpha: 0.5,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isSigningUp
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Sign Up'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: auth.isLoading ? null : widget.onSwitchToLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppPalette.authSubtitle,
                  ),
                  children: [
                    TextSpan(
                      text: 'Log In',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppPalette.authNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
