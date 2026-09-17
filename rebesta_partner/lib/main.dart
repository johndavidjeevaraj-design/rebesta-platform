import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/partner_fcm_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();

  debugPrint(
    '🔔 BACKGROUND PARTNER FCM: ${message.data}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  //final prefs = await SharedPreferences.getInstance();

  //await prefs.remove('partner_token');
  //await prefs.remove('partner_user_id');

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await PartnerFcmService.initialize();

  runApp(
    const RebestaPartnerApp(),
  );
}