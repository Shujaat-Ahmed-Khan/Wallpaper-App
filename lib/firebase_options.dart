import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoAdminKeyForNeonGlass2026',
    appId: '1:1029384756:web:abcd1234ef5678',
    messagingSenderId: '1029384756',
    projectId: 'neonglass-wallpaper',
    authDomain: 'neonglass-wallpaper.firebaseapp.com',
    storageBucket: 'neonglass-wallpaper.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoAdminKeyForNeonGlass2026',
    appId: '1:1029384756:android:abcd1234ef5678',
    messagingSenderId: '1029384756',
    projectId: 'neonglass-wallpaper',
    storageBucket: 'neonglass-wallpaper.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoAdminKeyForNeonGlass2026',
    appId: '1:1029384756:ios:abcd1234ef5678',
    messagingSenderId: '1029384756',
    projectId: 'neonglass-wallpaper',
    storageBucket: 'neonglass-wallpaper.appspot.com',
    iosBundleId: 'com.bitrops.wallpaperApp',
  );
}
