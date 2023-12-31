// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return ios;
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyAdOBFxPS1TacnK5OZTU6VxOQ20Bq8Cyrg',
    appId: '1:79998394043:web:af0eba9987ec6676d6139e',
    messagingSenderId: '79998394043',
    projectId: 'thermal-effort-366015',
    authDomain: 'thermal-effort-366015.firebaseapp.com',
    storageBucket: 'thermal-effort-366015.appspot.com',
    measurementId: 'G-0668RQE3NY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpxDuMIZrx55W6YuU6TY0v7T3Ar-Mg-Eo',
    appId: '1:79998394043:android:d6f175c1965daeb8d6139e',
    messagingSenderId: '79998394043',
    projectId: 'thermal-effort-366015',
    storageBucket: 'thermal-effort-366015.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXm4T-m7LSN9MzmMKIx7DwFWYi_IFVpVA',
    appId: '1:79998394043:ios:ca170fb92f4d9815d6139e',
    messagingSenderId: '79998394043',
    projectId: 'thermal-effort-366015',
    storageBucket: 'thermal-effort-366015.appspot.com',
    androidClientId: '79998394043-2llu6cka2h7lijqk1kds6m2056ub99vu.apps.googleusercontent.com',
    iosClientId: '79998394043-2fmkgchkbbmllhqbbskr3dlrgm5sdiuh.apps.googleusercontent.com',
    iosBundleId: 'com.boha.kasieTransieMarshal',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAXm4T-m7LSN9MzmMKIx7DwFWYi_IFVpVA',
    appId: '1:79998394043:ios:bd0196cc456b5abed6139e',
    messagingSenderId: '79998394043',
    projectId: 'thermal-effort-366015',
    storageBucket: 'thermal-effort-366015.appspot.com',
    androidClientId: '79998394043-2llu6cka2h7lijqk1kds6m2056ub99vu.apps.googleusercontent.com',
    iosClientId: '79998394043-02elar1ujjscr25i8a271alnlunllpm9.apps.googleusercontent.com',
    iosBundleId: 'com.boha.kasieTransieMarshal.RunnerTests',
  );
}
