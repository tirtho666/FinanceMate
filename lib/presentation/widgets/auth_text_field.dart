import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Rounded auth input styled after `assets/login_ui.png`: `#F8FAFC` fill,
/// `#CBD5E1` border and a dark navy prefix icon.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.enabled = true,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool enabled;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(12));

  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: textTheme.bodyMedium?.copyWith(color: AppPalette.authNavy),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppPalette.authSubtitle,
        ),
        filled: true,
        fillColor: AppPalette.authFieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: Icon(widget.prefixIcon, color: AppPalette.authNavy),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppPalette.authNavy,
                ),
              )
            : null,
        border: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppPalette.authFieldBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppPalette.authFieldBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppPalette.authNavy, width: 1.5),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppPalette.authFieldBorder),
        ),
      ),
    );
  }
}
