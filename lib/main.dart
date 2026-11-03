import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/notifications/push_notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Needed before runApp(): Android reads google-services.json via
  // the Google Services Gradle plugin (see README), so no extra
  // FirebaseOptions are passed here.
  //
  // Wrapped in try/catch on purpose: until google-services.json and
  // the Gradle plugin are wired up (see README's Firebase setup
  // steps), this throws. We don't want that to block the whole app —
  // login and the orders list work fine without push notifications,
  // and PushNotificationsService.initialize() has its own matching
  // try/catch so the rest of the app behaves the same way either way.
  try {
    await Firebase.initializeApp();

    // Must be registered at top level, outside any widget, so
    // Firebase can call it from a background isolate when a message
    // arrives while the app isn't in the foreground.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase not set up yet — push notifications are disabled. ($e)');
  }

  runApp(const WcOrderManagerApp());
}
