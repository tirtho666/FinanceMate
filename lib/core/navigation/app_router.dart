import 'package:flutter/material.dart';

import '../../presentation/screens/auth_screen.dart';
import '../../presentation/screens/lock_screen.dart';
import '../../presentation/screens/main_wrapper_screen.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.main:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MainWrapperScreen(),
        );
      case AppRoutes.lock:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LockScreen(),
        );
      case AppRoutes.auth:
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AuthScreen(),
        );
    }
  }
}