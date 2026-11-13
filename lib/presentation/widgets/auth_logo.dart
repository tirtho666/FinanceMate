import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/image_0.png',
      height: 96,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
