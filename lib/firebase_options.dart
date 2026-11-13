// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- Android Configuration ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAn9wmD-jtLJErvdRSK0c7PfAM1yu6MAis',
    appId: '1:204367029272:android:0b0868cbd76558dd9c8f6d',
    messagingSenderId: '204367029272',
    projectId: 'finance-mate-764fa',
    storageBucket: 'finance-mate-764fa.firebasestorage.app',
  );

  // --- iOS Configuration ---
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCB0ZnW4BXEotNhTIcOniZQ2IusJ-Azs4A',
    appId: '1:204367029272:ios:e65bca79a9f2de4f9c8f6d',
    messagingSenderId: '204367029272',
    projectId: 'finance-mate-764fa',
    storageBucket: 'finance-mate-764fa.firebasestorage.app',
    iosBundleId: 'com.example.financemate', // আপনার প্রজেক্টের বান্ডেল আইডি
  );
}