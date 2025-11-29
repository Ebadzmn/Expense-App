import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/home_controller.dart';

class CustomBottomNavBar extends StatelessWidget {
  final bool isDarkMode;

  const CustomBottomNavBar({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final activeColor = isDarkMode ? Colors.white : const Color(0xFF2196F3);
    final inactiveColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return Container(
      height: screenHeight * 0.1,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121212) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildNavItem(
              0,
              'assets/icons/home (2).png',
              'home'.tr,
              screenWidth,
              homeController,
              activeColor,
              inactiveColor,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              1,
              'assets/icons/analysis.png',
              'analytics'.tr,
              screenWidth,
              homeController,
              activeColor,
              inactiveColor,
            ),
          ),
          SizedBox(
            width: screenWidth * 0.18,
            child: GestureDetector(
              onTap: () =>
                  homeController.navigateToAddTransaction(isExpense: true),
              child: Container(
                width: screenWidth * 0.14,
                height: screenWidth * 0.14,
                decoration: const BoxDecoration(
                  color: Color(0xFF2196F3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/plus.png',
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildNavItem(
              2,
              'assets/icons/compare.png',
              'comparison'.tr,
              screenWidth,
              homeController,
              activeColor,
              inactiveColor,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              3,
              'assets/icons/setting.png',
              'settings'.tr,
              screenWidth,
              homeController,
              activeColor,
              inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String iconPath,
    String label,
    double screenWidth,
    HomeController homeController,
    Color activeColor,
    Color inactiveColor,
  ) {
    return Obx(() {
      bool isActive = homeController.selectedNavIndex.value == index;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          try {
            await homeController.changeNavIndex(index);
          } catch (e) {
            print('Navbar tap error for index $index: $e');
            homeController.setNavIndex(index);
            switch (index) {
              case 0:
                if (Get.currentRoute != '/mainHome')
                  Get.offAllNamed('/mainHome');
                break;
              case 1:
                Get.toNamed('/analytics');
                break;
              case 2:
                Get.toNamed('/comparison');
                break;
              case 3:
                Get.toNamed('/settings');
                break;
            }
          }
        },
        child: Container(
          width: double.infinity,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
                color: isActive ? activeColor : inactiveColor,
              ),
              SizedBox(height: screenWidth * 0.015),
              Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isActive) ...[
                SizedBox(height: screenWidth * 0.005),
                Container(
                  width: screenWidth * 0.05,
                  height: 2,
                  color: activeColor,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
