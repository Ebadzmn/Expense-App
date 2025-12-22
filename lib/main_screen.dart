import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:your_expense/Analytics/main_analytics_screen.dart';
import 'package:your_expense/Comparison/Comparison_screen.dart';
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/Settings/main_setting_screen.dart';
import 'package:your_expense/home/home_controller.dart';
import 'package:your_expense/home/home_ui.dart';
import 'package:your_expense/reuseablenav/reuseablenavui.dart';

import 'Comparison/MarketplaceService.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<MarketplaceService>()) {
      Get.lazyPut<MarketplaceService>(() => MarketplaceService());
    }

    final args = Get.arguments as Map<String, dynamic>?;
    final argIndex = args?['tabIndex'];
    final idx = (argIndex is int)
        ? argIndex
        : (argIndex is num)
            ? argIndex.toInt()
            : widget.initialIndex;
    final int safeIdx = idx.clamp(0, 3);
    
    // Defer state update to avoid "setState() during build" if MainScreen is rebuilt immediately
    Future.microtask(() {
      if (Get.find<HomeController>().selectedNavIndex.value != safeIdx) {
        Get.find<HomeController>().selectedNavIndex.value = safeIdx;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final homeController = Get.find<HomeController>();
      final themeController = Get.find<ThemeController>();
      final int currentIndex = homeController.selectedNavIndex.value.clamp(0, 3);

      return WillPopScope(
        onWillPop: () async {
          if (homeController.selectedNavIndex.value != 0) {
            homeController.selectedNavIndex.value = 0;
            return false;
          }
          return true;
        },
        child: Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: const [
              MainHomeScreen(showBottomNav: false),
              AnalyticsScreen(isEmbeddedInMain: true),
              ComparisonPageScreen(isFromExpense: true, isEmbeddedInMain: true),
              SettingsScreen(isEmbeddedInMain: true),
            ],
          ),
          bottomNavigationBar:
              CustomBottomNavBar(isDarkMode: themeController.isDarkModeActive),
        ),
      );
    });
  }
}
