import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/mot_notification_service.dart';
import 'services/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ads
  try {
    await MobileAds.instance.initialize();
  } catch (_) {
    // ignore
  }

  // Subscription status (paywall)
  try {
    await SubscriptionService.init();
  } catch (_) {
    // ignore
  }

  // MOT notifications
  try {
    await MotNotificationService.init();
    await MotNotificationService.requestPermissionIfNeeded();

    // ✅ only schedule Trade notifications if subscribed
    if (SubscriptionService.isSubscribed) {
      await MotNotificationService.rescheduleTradeTodayAlerts();
    }
  } catch (_) {
    // ignore
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MOT Booking helper',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: Colors.blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}