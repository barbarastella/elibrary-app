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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnF0xfPFMyiGEKsjeNY33Ys_hcBvamHHY',
    appId: '1:808982282093:web:82e783b2f8ffc9ae2d6464',
    messagingSenderId: '808982282093',
    projectId: 'bsw-elibrary',
    authDomain: 'bsw-elibrary.firebaseapp.com',
    storageBucket: 'bsw-elibrary.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChSVNjgQ2_QYnxGM2k_uyDKsJNcjeJ84A',
    appId: '1:808982282093:android:5b96daaf180895e02d6464',
    messagingSenderId: '808982282093',
    projectId: 'bsw-elibrary',
    storageBucket: 'bsw-elibrary.firebasestorage.app',
  );
}
