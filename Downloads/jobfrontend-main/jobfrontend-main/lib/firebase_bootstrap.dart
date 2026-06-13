import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase when native/web config is present. Safe no-op on failure.
Future<void> tryInitializeFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp();
  } catch (e, st) {
    debugPrint('Firebase initialization skipped: $e\n$st');
  }
}
