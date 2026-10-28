// Firebase settings for the DisasTrack project (disastrackdb).
// These values identify the project; they are not secrets. Access is
// controlled by your Realtime Database rules.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static const _todo = 'PASTE_HERE';

  static bool get isConfigured =>
      currentPlatform.apiKey != _todo && currentPlatform.appId != _todo;

  static FirebaseOptions get currentPlatform => kIsWeb ? web : android;

  static const _dbUrl = 'https://disastrackdb-default-rtdb.firebaseio.com';

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyAQRfrMWxsC7w3srWcuYuugHInaZJ2LkOQ',
    appId: '1:564192944628:android:34367bb28829a9410419a1',
    messagingSenderId: '564192944628',
    projectId: 'disastrackdb',
    storageBucket: 'disastrackdb.firebasestorage.app',
    databaseURL: 'https://disastrackdb-default-rtdb.firebaseio.com',
  );

  // Only needed if you run the app in a browser. Register a Web app in
  // Firebase (Project settings -> Your apps) and paste its values here.
  static const web = FirebaseOptions(
      apiKey: "AIzaSyDzodK8IT9kEXUHvXfbhlCkAxYONJaq7zI",
      authDomain: "disastrackdb.firebaseapp.com",
      databaseURL: "https://disastrackdb-default-rtdb.firebaseio.com",
      projectId: "disastrackdb",
      storageBucket: "disastrackdb.firebasestorage.app",
      messagingSenderId: "564192944628",
      appId: "1:564192944628:web:9f365d8b6fa9b8060419a1",
      measurementId: "G-9Z6N6Y6WRS");
}
