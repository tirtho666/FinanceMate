import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'core/di/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp ke ekhane await na kore direct UI load kora hocche
  runApp(const AppInitWrapper());
}

class AppInitWrapper extends StatefulWidget {
  const AppInitWrapper({super.key});

  @override
  State<AppInitWrapper> createState() => _AppInitWrapperState();
}

class _AppInitWrapperState extends State<AppInitWrapper> {
  late Future<FirebaseApp> _firebaseInitialization;

  @override
  void initState() {
    super.initState();
    // Background-e Firebase initialize hobe, jar fole screen black hobe na
    _firebaseInitialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firebaseInitialization,
      builder: (context, snapshot) {
        // Firebase load howar somoy amader custom Logo screen show korbe
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/image_0.png',
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(
                      color: Color(0xFF082E4A),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Firebase connect hoye gele main app load hobe
        return MultiProvider(
          providers: AppProviders.list,
          child: const FinanceMateApp(),
        );
      },
    );
  }
}