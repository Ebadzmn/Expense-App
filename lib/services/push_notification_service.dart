import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:your_expense/firebase_options.dart';
import 'package:your_expense/routes/app_routes.dart';

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

    // 1b) Permission (Android 13+): Request runtime notification permission
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          final result = await Permission.notification.request();
          debugPrint('[Push] Android notification permission: $result');
        } else {
          debugPrint('[Push] Android notification permission already granted');
        }
      } catch (e) {
        debugPrint('[Push] Android notification permission request error: $e');
      }
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

    // If iOS APNs was slow and FCM token is still empty, retry in background.
    if (Platform.isIOS && (_fcmToken.value.isEmpty)) {
      Future.microtask(() => _retryFetchTokenIfApnsReady());
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

        // Navigate for monthly report even when app is in foreground
        final type = message.data['type'];
        if (type == 'monthly_report') {
          final String? month = message.data['month'];
          Get.toNamed(
            AppRoutes.uploadToDrive,
            arguments: {
              'prefill': 'monthly_report',
              if (month != null) 'month': month,
            },
          );
        }
      } catch (e) {
        debugPrint('[Push] onMessage handler error: $e');
      }
    });

    // 6) Tap-from-background/terminated handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      try {
        debugPrint('[Push] onMessageOpenedApp data: ${message.data}');
        final type = message.data['type'];
        if (type == 'monthly_report') {
          final String? month = message.data['month'];
          Get.toNamed(
            AppRoutes.uploadToDrive,
            arguments: {
              'prefill': 'monthly_report',
              if (month != null) 'month': month,
            },
          );
        }
      } catch (e) {
        debugPrint('[Push] onMessageOpenedApp error: $e');
      }
    });

    // 7) Cold-start notification when app opened by tapping a notification
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[Push] getInitialMessage data: ${initialMessage.data}');
        final type = initialMessage.data['type'];
        if (type == 'monthly_report') {
          final String? month = initialMessage.data['month'];
          Get.toNamed(
            AppRoutes.uploadToDrive,
            arguments: {
              'prefill': 'monthly_report',
              if (month != null) 'month': month,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('[Push] getInitialMessage error: $e');
    }

    debugPrint('[Push] init() done');
    return this;
  }

  /// iOS: APNs token ready হওয়া পর্যন্ত poll করি, তারপর FCM token নিবো
  Future<String?> _waitForApnsToken({
    Duration timeout = const Duration(seconds: 60),
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

  /// If APNs arrives late, retry fetching FCM token for a limited time.
  Future<void> _retryFetchTokenIfApnsReady({
    Duration overallTimeout = const Duration(minutes: 2),
    Duration pollInterval = const Duration(seconds: 1),
  }) async {
    if (!Platform.isIOS) return;

    final sw = Stopwatch()..start();
    while (sw.elapsed < overallTimeout && (_fcmToken.value.isEmpty)) {
      try {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null && apns.isNotEmpty) {
          debugPrint('[Push] APNs token arrived late: $apns');
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) {
            _fcmToken.value = token;
            debugPrint('[Push] FCM token fetched after APNs ready: $token');
            break;
          }
        }
      } catch (e) {
        debugPrint('[Push] late APNs/FCM fetch error: $e');
      }
      await Future.delayed(pollInterval);
    }
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
