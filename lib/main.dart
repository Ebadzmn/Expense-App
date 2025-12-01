// lib/main.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'package:your_expense/config/app_config.dart';
import 'package:your_expense/firebase_options.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/services/face_id_service.dart';
import 'package:your_expense/services/push_notification_service.dart';
import 'package:your_expense/services/token_service.dart';
import 'package:your_expense/Analytics/income_service.dart';

// ... your existing imports

Future<void> main() async {
  final appStartSw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize core services first
  await Future.wait([
    Get.putAsync(() => ConfigService().init()),
    Get.putAsync(() => TokenService().init()),
    Get.putAsync(() => ApiBaseService().init()),
    Get.putAsync(() => FaceIdService().init()),
  ]);

  // Initialize services that depend on the core services
  await Get.putAsync(() => IncomeService().init());

  // IMPORTANT: Do NOT initialize MobileAds here. We gate it behind ATT after first frame.

  // Build UI immediately (so splash → first frame happens quickly)
  runApp(AppConfig.app);

  // ATT + AdMob startup flow: run after first frame with a small delay for stability.
  Future(() async {
    await _requestATTThenInitAds();
    // If you pre-load any rewarded/interstitial ads, do it here AFTER initialize() finishes.
    // Example: no-op; your AdHelper.load/show methods will work when called later.
  });

  // ... keep your existing background bootstrap, Android storage permission, etc.
}

/// Requests Apple's App Tracking Transparency (ATT) on iOS, then initializes AdMob.
/// - Shows ATT on first launch (status notDetermined) with a 400ms delay after first frame.
/// - Initializes AdMob only after ATT status is resolved.
/// - Android/Web: skips ATT and initializes AdMob directly.
Future<void> _requestATTThenInitAds() async {
  try {
    if (kIsWeb) return;

    if (Platform.isIOS) {
      // Read current status
      TrackingStatus status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('[ATT] Initial status: $status');

      // Only request if notDetermined
      if (status == TrackingStatus.notDetermined) {
        // Small delay to ensure splash → first frame is presented before ATT
        await Future.delayed(const Duration(milliseconds: 400));
        // Show ATT prompt
        status = await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('[ATT] Request completed: $status');
      }

      // Proceed to AdMob initialization regardless of ATT outcome
      await _initAdMob();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android: initialize AdMob directly
      await _initAdMob();
    }
  } catch (e) {
    debugPrint('[ATT] Flow error: $e');
    // Fallback so ads are not blocked if ATT flow throws
    try {
      await _initAdMob();
    } catch (_) {}
  }
}

/// Initializes Google Mobile Ads SDK and applies optional debug configuration.
/// Call this ONLY after ATT flow completes on iOS.
Future<void> _initAdMob() async {
  try {
    await MobileAds.instance.initialize();
    debugPrint('[Ads] MobileAds initialized after ATT resolution');
    if (kDebugMode) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: const [
            // Example Android test device ID
            '5EFC723B6630B42FFF41E5FA02E7A513',
          ],
        ),
      );
      debugPrint('[Ads] RequestConfiguration set (debug testDeviceIds)');
    }
    // Optional: preload rewarded/interstitial ads here if you use a global loader
    // e.g., RewardedAd.load(...), InterstitialAd.load(...)
  } catch (e) {
    debugPrint('[Ads] MobileAds initialization failed: $e');
  }
}
