import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_lock_provider.dart';
import 'presentation/widgets/auth_logo.dart';

class FinanceMateApp extends StatelessWidget {
  const FinanceMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      // Routing problem solve korar jonno initialRoute byabohar kora holo
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
      },
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _minimumSplashDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Restores the persisted JWT session and loads the App Lock hash into RAM
  /// before deciding which screen the app opens on.
  Future<void> _bootstrap() async {
    final storage = context.read<SecureStorageService>();
    final appLock = context.read<AppLockProvider>();

    String route = AppRoutes.auth;
    try {
      await Future.wait<void>([
        storage.restore(),
        appLock.load(),
        Future<void>.delayed(_minimumSplashDuration),
      ]);
      if (storage.hasSession) {
        route = appLock.isEnabled ? AppRoutes.lock : AppRoutes.main;
      }
    } catch (_) {
      // A keystore read failure must not trap the user on the splash screen.
      route = AppRoutes.auth;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AuthLogo(iconSize: 96, fontSize: 30),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFF082E4A),
            ),
          ],
        ),
      ),
    );
  }
}
