import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

bool _registered = false;

void registerRoomWebPlugins() {
  if (_registered) return;
  // Explicitly select the web delegates before deferred Firebase initialization.
  FirebaseAuthWeb.registerWith(webPluginRegistrar);
  FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
  _registered = true;
}
