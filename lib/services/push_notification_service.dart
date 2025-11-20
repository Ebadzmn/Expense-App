import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:your_expense/firebase_options.dart';

class PushNotificationService extends GetxService {
  final RxString _fcmToken = ''.obs;

  String? getToken() => _fcmToken.value.isNotEmpty ? _fcmToken.value : null;

  Future<PushNotificationService> init() async {
    debugPrint('[Push] init() start');

    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1) Permission (iOS/macOS)
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      debugPrint('[Push] iOS authorizationStatus: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[Push] requestPermission error: $e');
    }

    // 2) Foreground presentation options (iOS)
    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[Push] setForegroundNotificationPresentationOptions error: $e');
    }

    // 3) Auto-init + APNs wait (iOS) + FCM token
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);

      if (Platform.isIOS) {
        await _waitForApnsToken();
      }

      final token = await messaging.getToken();
      _fcmToken.value = token ?? '';
      debugPrint('[Push] Initial FCM token: ${_fcmToken.value}');
    } catch (e) {
      debugPrint('[Push] getToken error: $e');
    }

    // 4) Token refresh listener
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _fcmToken.value = newToken;
      debugPrint('[Push] Refreshed FCM token: $newToken');
    });

    // 5) Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        final notif = message.notification;
        final title = notif?.title ?? 'Notification';
        final body = notif?.body ?? '';

        // Simple in-app snackbar
        Get.snackbar(
          title,
          body,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );

        debugPrint('[Push] onMessage data: ${message.data}');
      } catch (e) {
        debugPrint('[Push] onMessage handler error: $e');
      }
    });

    debugPrint('[Push] init() done');
    return this;
  }

  /// iOS: APNs token ready হওয়া পর্যন্ত poll করি, তারপর FCM token নিবো
  Future<String?> _waitForApnsToken({
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    if (!Platform.isIOS) return null;

    final messaging = FirebaseMessaging.instance;
    final sw = Stopwatch()..start();
    String? apns;

    debugPrint('[Push] Waiting for APNs token...');

    while (sw.elapsed < timeout) {
      try {
        apns = await messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) {
          debugPrint('[Push] APNs token ready: $apns');
          return apns;
        }
      } catch (e) {
        debugPrint('[Push] getAPNSToken error: $e');
      }

      await Future.delayed(pollInterval);
    }

    debugPrint('[Push] APNs token NOT ready within ${timeout.inSeconds}s');
    return null;
  }
}

/// MUST be top-level + entry-point for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Ignore if already initialized
  }

  debugPrint('[Push][BG] Message data: ${message.data}');
  if (message.notification != null) {
    debugPrint(
      '[Push][BG] Notification: ${message.notification!.title} / ${message.notification!.body}',
    );
  }
}
