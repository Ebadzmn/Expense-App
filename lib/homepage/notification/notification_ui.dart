// Updated NotificationScreen - Replace your existing NotificationScreen with this
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Settings/appearance/ThemeController.dart';
import 'notification_controller.dart';
 // Adjust path to your NotificationController

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final NotificationController controller = Get.put(NotificationController());
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          backgroundColor: themeController.isDarkMode.value
              ? const Color(0xFF121212)
              : Colors.white,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final orderedKeys = controller.orderedSectionKeys;
      final bool hasNotifications = orderedKeys.isNotEmpty;

      return Scaffold(
        backgroundColor: themeController.isDarkMode.value
            ? const Color(0xFF121212)
            : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: themeController.isDarkMode.value
                            ? Colors.white
                            : Colors.black,
                        size: screenWidth * 0.05,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: themeController.isDarkMode.value
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.05),
                  ],
                ),
              ),
              // Notifications List
              Expanded(
                child: hasNotifications
                    ? RefreshIndicator(
                  onRefresh: controller.fetchNotifications,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    itemCount: orderedKeys.length,
                    separatorBuilder: (context, index) => SizedBox(height: screenHeight * 0.03),
                    itemBuilder: (context, index) {
                      final key = orderedKeys[index];
                      final items = controller.groupedNotifications[key] ?? [];
                      final bool isDarkMode = themeController.isDarkMode.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateSection(key, screenWidth, isDarkMode),
                          ...items.map<Widget>((notif) {
                            return _buildNotificationItem(
                              screenWidth,
                              screenHeight,
                              isDarkMode,
                              notif['title'] as String,
                              notif['time'] as String,
                            );
                          }),
                        ],
                      );
                    },
                  ),
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: screenWidth * 0.15,
                        color: themeController.isDarkMode.value
                            ? Colors.white54
                            : const Color(0xFF999999),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w500,
                          color: themeController.isDarkMode.value
                              ? Colors.white70
                              : const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDateSection(String date, double screenWidth, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.02,
        bottom: screenWidth * 0.03,
        top: screenWidth * 0.01,
      ),
      child: Text(
        date,
        style: TextStyle(
          fontSize: screenWidth * 0.038,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white70 : const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      double screenWidth,
      double screenHeight,
      bool isDarkMode,
      String title,
      String timeAgo,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              right: screenWidth * 0.03,
              top: screenHeight * 0.002,
            ),
            child: Icon(
              Icons.mail_outline,
              size: screenWidth * 0.055,
              color: isDarkMode ? Colors.white70 : const Color(0xFF666666),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : const Color(0xFF333333),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: screenHeight * 0.008),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.w400,
                    color: isDarkMode ? Colors.white54 : const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}