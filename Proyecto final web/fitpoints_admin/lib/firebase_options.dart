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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseOptions no configurado para Linux.',
        );
      default:
        throw UnsupportedError(
          'Plataforma no soportada.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC8-PDc8siGRRc4FySdl6CsDKfOh6CeYv0',
    appId: '1:240758500152:web:c380d2dc1d6e4be4ba6fcd',
    messagingSenderId: '240758500152',
    projectId: 'proyectofinal-d6fcd',
    authDomain: 'proyectofinal-d6fcd.firebaseapp.com',
    databaseURL: 'https://proyectofinal-d6fcd-default-rtdb.firebaseio.com',
    storageBucket: 'proyectofinal-d6fcd.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0oJoP56kVNjEVxoKmp6_eunucta2SmHg',
    appId: '1:29073594820:android:11374c0a44963ad0822c91',
    messagingSenderId: '29073594820',
    projectId: 'fitpoints-proyecto-final',
    storageBucket: 'fitpoints-proyecto-final.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCVe3jsyu6F8jpKXuniqZbTNxhdsAD190o',
    appId: '1:29073594820:ios:08012c419a813b05822c91',
    messagingSenderId: '29073594820',
    projectId: 'fitpoints-proyecto-final',
    storageBucket: 'fitpoints-proyecto-final.firebasestorage.app',
    iosBundleId: 'com.example.fitpointsAdmin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCVe3jsyu6F8jpKXuniqZbTNxhdsAD190o',
    appId: '1:29073594820:ios:08012c419a813b05822c91',
    messagingSenderId: '29073594820',
    projectId: 'fitpoints-proyecto-final',
    storageBucket: 'fitpoints-proyecto-final.firebasestorage.app',
    iosBundleId: 'com.example.fitpointsAdmin',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBgZzkwcGnHwJxrx3gy5qmk5QervuJcVD4',
    appId: '1:29073594820:web:2d6513ae2a1b8d32822c91',
    messagingSenderId: '29073594820',
    projectId: 'fitpoints-proyecto-final',
    authDomain: 'fitpoints-proyecto-final.firebaseapp.com',
    storageBucket: 'fitpoints-proyecto-final.firebasestorage.app',
  );
}
