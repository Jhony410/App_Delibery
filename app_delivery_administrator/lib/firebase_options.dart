// Firebase configuration for the Runa Admin Panel.
// Reuses the same Firebase project (delypuno-ddd2d) as the user and courier apps.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCrNcXd5NSJPSPrJ5nZiVqXaAa1f83NZpM',
    appId: '1:415943093114:web:2607a33dbdb8f7e9e1c4c3',
    messagingSenderId: '415943093114',
    projectId: 'delypuno-ddd2d',
    authDomain: 'delypuno-ddd2d.firebaseapp.com',
    storageBucket: 'delypuno-ddd2d.firebasestorage.app',
    measurementId: 'G-22WXGG3STR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9F7oswSQGyQrUTgpI3GJYt84Ccxnu7QU',
    appId: '1:415943093114:android:9025c4ac8a4547a3e1c4c3',
    messagingSenderId: '415943093114',
    projectId: 'delypuno-ddd2d',
    storageBucket: 'delypuno-ddd2d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuzzOHkwwqHWhyNc9QP0mZuek6zI4Io8Q',
    appId: '1:415943093114:ios:744fc51369b224e6e1c4c3',
    messagingSenderId: '415943093114',
    projectId: 'delypuno-ddd2d',
    storageBucket: 'delypuno-ddd2d.firebasestorage.app',
    iosBundleId: 'com.example.appDeliveryAdministrator',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCrNcXd5NSJPSPrJ5nZiVqXaAa1f83NZpM',
    appId: '1:415943093114:web:f7f9ebe4aaf6d785e1c4c3',
    messagingSenderId: '415943093114',
    projectId: 'delypuno-ddd2d',
    authDomain: 'delypuno-ddd2d.firebaseapp.com',
    storageBucket: 'delypuno-ddd2d.firebasestorage.app',
    measurementId: 'G-YF25XLRSZ7',
  );
}
