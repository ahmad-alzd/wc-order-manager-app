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
  await Firebase.initializeApp();

  // Must be registered at top level, outside any widget, so Firebase
  // can call it from a background isolate when a message arrives
  // while the app isn't in the foreground.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const WcOrderManagerApp());
}
