import 'dart:convert';
import 'package:bingo/firebase_options.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'room_web_plugins.dart';

class RoomFirebase {
  static const config = String.fromEnvironment('FIREBASE_WEB_CONFIG');
  static const emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  static bool get configured =>
      config.isNotEmpty ||
      DefaultFirebaseOptions.currentPlatform.projectId.isNotEmpty;
  static Future<void>? _initializing;

  static Future<void> initialize() => _initializing ??= _initialize();

  static Future<void> _initialize() async {
    if (!configured) {
      throw StateError(
        'Configure o Firebase para criar e entrar em salas. Veja docs/firebase-rooms.md.',
      );
    }
    try {
      registerRoomWebPlugins();
      final data = config.isEmpty
          ? null
          : jsonDecode(config) as Map<String, dynamic>;
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: data == null
              ? DefaultFirebaseOptions.currentPlatform
              : FirebaseOptions(
                  apiKey: data['apiKey'] as String,
                  appId: data['appId'] as String,
                  messagingSenderId: data['messagingSenderId'] as String,
                  projectId: data['projectId'] as String,
                  authDomain: data['authDomain'] as String?,
                  storageBucket: data['storageBucket'] as String?,
                ),
        );
        if (emulatorHost.isNotEmpty) {
          await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
          FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8081);
        }
      }
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }
}
