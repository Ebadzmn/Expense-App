import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationsService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? _androidChannel;
  SharedPreferences? _prefs;

  static const String _prefsKeyPrefix = 'budget_notifications_'; // e.g., budget_notifications_2025-11

  Future<LocalNotificationsService> init() async {
    _prefs = await SharedPreferences.getInstance();

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    // Android channel
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _androidChannel = const AndroidNotificationChannel(
        'budget_alerts_channel',
        'Budget Alerts',
        description: 'Alerts when spending reaches budget thresholds',
        importance: Importance.high,
      );
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_androidChannel!);
      // Android 13+ notification runtime permission
      try {
        await Permission.notification.request();
      } catch (_) {}
    }

    // iOS: request permissions explicitly
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return this;
  }

  Future<void> checkBudgetThresholds({
    required String month,
    required double spentPercentage,
    required double monthlyBudget,
    double? leftAmount,
  }) async {
    if (monthlyBudget <= 0) return; // No budget set

    final thresholds = [50, 75, 90, 100];
    final key = '$_prefsKeyPrefix$month';
    final triggered = _prefs?.getStringList(key) ?? <String>[];

    for (final t in thresholds) {
      if (spentPercentage >= t && !triggered.contains(t.toString())) {
        await _showBudgetNotification(t, spentPercentage, monthlyBudget, leftAmount: leftAmount);
        triggered.add(t.toString());
        await _prefs?.setStringList(key, triggered);
      }
    }
  }

  Future<void> resetMonth(String month) async {
    final key = '$_prefsKeyPrefix$month';
    await _prefs?.remove(key);
  }

  Future<void> _showBudgetNotification(
    int threshold,
    double currentPercent,
    double monthlyBudget, {
    double? leftAmount,
  }) async {
    final title = 'Budget Alert: $threshold% reached';
    final remaining = (leftAmount ?? (monthlyBudget * (100 - currentPercent) / 100)).clamp(0.0, double.infinity);
    final body = threshold >= 100
        ? 'You have spent 100% of your monthly budget.'
        : 'You have spent ${currentPercent.toStringAsFixed(0)}% of your budget. Remaining: ${remaining.toStringAsFixed(2)}';

    final androidDetails = AndroidNotificationDetails(
      _androidChannel?.id ?? 'budget_alerts_channel',
      _androidChannel?.name ?? 'Budget Alerts',
      channelDescription: _androidChannel?.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: false);
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      threshold, // id per threshold
      title,
      body,
      details,
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _androidChannel?.id ?? 'budget_alerts_channel',
      _androidChannel?.name ?? 'Budget Alerts',
      channelDescription: _androidChannel?.description ?? 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: false);
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final int effectiveId = id ?? DateTime.now().millisecondsSinceEpoch % 1000000000;
    await _plugin.show(effectiveId, title, body, details);
  }
}