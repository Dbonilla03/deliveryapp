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
    apiKey: 'AIzaSyDFNV8BhiQtfJY1ss9qvppQL6KVAp9EMhs',
    appId: '1:355853926438:web:a9c6cf72f787eecca826e7',
    messagingSenderId: '355853926438',
    projectId: 'deliveryapp-44185',
    authDomain: 'deliveryapp-44185.firebaseapp.com',
    storageBucket: 'deliveryapp-44185.appspot.com',
    measurementId: 'G-8R5P2RB9YP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCn_l6Sog0HmvLaBfHRr85uLtZvL0pPI1Y',
    appId: '1:355853926438:android:645a61844f49098ea826e7',
    messagingSenderId: '355853926438',
    projectId: 'deliveryapp-44185',
    storageBucket: 'deliveryapp-44185.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXWXdta5oE4W2lF2wK_zwhjCpMWUdMqSs',
    appId: '1:355853926438:ios:dee353bfefe81623a826e7',
    messagingSenderId: '355853926438',
    projectId: 'deliveryapp-44185',
    storageBucket: 'deliveryapp-44185.appspot.com',
    iosBundleId: 'com.example.deliveryapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAXWXdta5oE4W2lF2wK_zwhjCpMWUdMqSs',
    appId: '1:355853926438:ios:be4be105ea530efda826e7',
    messagingSenderId: '355853926438',
    projectId: 'deliveryapp-44185',
    storageBucket: 'deliveryapp-44185.appspot.com',
    iosBundleId: 'com.example.deliveryapp.RunnerTests',
  );
}