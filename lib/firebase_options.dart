import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBeQJwLuihbuT84kt4D419uN3cTVgqZ9ZU',
    authDomain: 'aura-estandar.firebaseapp.com',
    projectId: 'aura-estandar',
    storageBucket: 'aura-estandar.firebasestorage.app',
    messagingSenderId: '308427922086',
    appId: '1:308427922086:web:688a25d809d2cdf591f267',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBK_RVkTsMKIKrtdHHaXLDVvNfLRE9jZ94',
    appId: '1:308427922086:android:f8af89cc138d9a1b91f267',
    messagingSenderId: '308427922086',
    projectId: 'aura-estandar',
    storageBucket: 'aura-estandar.firebasestorage.app',
  );
}