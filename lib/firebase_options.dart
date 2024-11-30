// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyDcAXlT6hoou41oEgIbjRTCagAJzBTsZIM',
    appId: '1:854189510560:web:4e6e9f73ae347af536dec5',
    messagingSenderId: '854189510560',
    projectId: 'kasie-transie-3',
    authDomain: 'kasie-transie-3.firebaseapp.com',
    storageBucket: 'kasie-transie-3.appspot.com',
    measurementId: 'G-BQW5ZWEKB4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB3finIgPi481q3-GaEDjOLcoPbs664gTs',
    appId: '1:854189510560:android:e104656a79f7fb4236dec5',
    messagingSenderId: '854189510560',
    projectId: 'kasie-transie-3',
    storageBucket: 'kasie-transie-3.appspot.com',
  );
}
