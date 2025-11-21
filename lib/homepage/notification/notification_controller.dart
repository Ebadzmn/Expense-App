// Updated file: controllers/notification_controller.dart (adjust path as needed)
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/api_base_service.dart';
import '../../services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_notifications_service.dart';


class NotificationController extends GetxController {
  final ApiBaseService _api = Get.find<ApiBaseService>();
  final ConfigService _config = Get.find<ConfigService>();

  var notifications = <Map<String, dynamic>>[].obs;
  var groupedNotifications = <String, List<Map<String, dynamic>>>{}.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final response = await _api.request(
        'GET',
        _config.notificationsEndpoint,
        requiresAuth: true,
      );

      // Be tolerant of different response shapes
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          if (data['notifications'] is List) {
            rawList = data['notifications'] as List<dynamic>;
          } else if (data['items'] is List) {
            rawList = data['items'] as List<dynamic>;
          }
        }
        // Fallbacks if top-level contains lists
        if (rawList.isEmpty) {
          if (response['notifications'] is List) {
            rawList = response['notifications'] as List<dynamic>;
          } else if (response['items'] is List) {
            rawList = response['items'] as List<dynamic>;
          }
        }
      }

      // Map to UI-friendly structure; tolerate field name differences
      notifications.value = rawList
          .whereType<Map<String, dynamic>>()
          .map<Map<String, dynamic>>((item) {
        final String title = (item['title'] ?? item['message'] ?? item['body'] ?? item['text'] ?? 'No title').toString();
        final dynamic ts = item['created_at'] ?? item['createdAt'] ?? item['timestamp'] ?? item['time'] ?? item['date'];
        final DateTime dateTime = _parseDate(ts);
        final String dateSection = _getDateSection(dateTime);
        final String timeAgo = _getRelativeTime(dateTime);
        return {
          'title': title,
          'time': timeAgo,
          'dateSection': dateSection,
          'dateTime': dateTime,
        };
      }).toList();

      _groupNotifications();

      // Trigger local notifications for newly arrived items
      await _triggerLocalNotificationsForNewItems();
    } catch (e) {
      print('Error fetching notifications: $e');
      Get.snackbar('Error', 'Failed to load notifications: ${e.toString()}');
      notifications.value = [];
      groupedNotifications.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void _groupNotifications() {
    groupedNotifications.clear();
    final sorted = List<Map<String, dynamic>>.from(notifications)
      ..sort((a, b) => b['dateTime'].compareTo(a['dateTime']));
    for (var notif in sorted) {
      final key = notif['dateSection'] as String;
      if (!groupedNotifications.containsKey(key)) {
        groupedNotifications[key] = [];
      }
      groupedNotifications[key]!.add(notif);
    }
  }

  List<String> get orderedSectionKeys {
    final keys = groupedNotifications.keys.toList();
    final today = 'Today';
    final yesterday = 'Yesterday';
    List<String> ordered = [];
    if (keys.contains(today)) ordered.add(today);
    if (keys.contains(yesterday)) ordered.add(yesterday);
    final others = keys.where((k) => k != today && k != yesterday).toList();
    others.sort((a, b) {
      final da = DateFormat('MMMM d, yyyy').parse(a);
      final db = DateFormat('MMMM d, yyyy').parse(b);
      return db.compareTo(da); // Descending order for older dates
    });
    ordered.addAll(others);
    return ordered;
  }

  String _getDateSection(DateTime dt) {
    final now = DateTime.now();
    if (now.year == dt.year && now.month == dt.month && now.day == dt.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == dt.year && yesterday.month == dt.month && yesterday.day == dt.day) {
      return 'Yesterday';
    }
    return DateFormat('MMMM d, yyyy').format(dt);
  }

  String _getRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }

  // Robust date parsing that handles ISO strings and common formats/epoch
  DateTime _parseDate(dynamic v) {
    try {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is int) {
        // Treat large ints as milliseconds, small as seconds
        if (v > 100000000000) {
          return DateTime.fromMillisecondsSinceEpoch(v);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(v * 1000);
        }
      }
      if (v is String) {
        // First try ISO8601 (convert to local for grouping correctness)
        try {
          return DateTime.parse(v).toLocal();
        } catch (_) {}
        // Common backend formats
        final patterns = [
          'yyyy-MM-dd HH:mm:ss',
          'yyyy/MM/dd HH:mm:ss',
          'dd-MM-yyyy HH:mm:ss',
          'MM/dd/yyyy HH:mm:ss',
          'yyyy-MM-dd',
        ];
        for (final p in patterns) {
          try {
            return DateFormat(p).parse(v, true).toLocal();
          } catch (_) {}
        }
      }
      return DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> _triggerLocalNotificationsForNewItems() async {
    try {
      if (!Get.isRegistered<LocalNotificationsService>()) return;
      final notifier = Get.find<LocalNotificationsService>();
      final prefs = await SharedPreferences.getInstance();
      final lastSeenMillis = prefs.getInt('notifications_last_seen_ts') ?? 0;
      final lastSeen = lastSeenMillis > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastSeenMillis)
          : DateTime.fromMillisecondsSinceEpoch(0);

      // Find new items after last seen
      final newItems = notifications
          .where((n) => (n['dateTime'] as DateTime).isAfter(lastSeen))
          .toList()
        ..sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));

      // Limit to avoid notification flood
      final int limit = newItems.length > 3 ? 3 : newItems.length;
      for (int i = 0; i < limit; i++) {
        final item = newItems[i];
        final title = (item['title'] as String?) ?? 'New notification';
        final timeAgo = (item['time'] as String?) ?? '';
        await notifier.showNotification(title: title, body: timeAgo);
      }

      // Update last seen to newest notification timestamp
      if (notifications.isNotEmpty) {
        final newest = notifications
            .map((n) => n['dateTime'] as DateTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        await prefs.setInt('notifications_last_seen_ts', newest.millisecondsSinceEpoch);
      }
    } catch (e) {
      // Soft fail — never block UI
      print('NotificationController: local notification trigger failed: $e');
    }
  }
}