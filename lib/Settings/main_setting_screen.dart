import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_expense/Settings/userprofile/profile_services.dart';
import '../home/home_controller.dart';
import '../routes/app_routes.dart';

import '../Settings/appearance/ThemeController.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/config_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isEmbeddedInMain;

  const SettingsScreen({super.key, this.isEmbeddedInMain = false});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final HomeController homeController;
  late final ThemeController themeController;
  late final ProfileService profileService;
  SharedPreferences? _prefs;
  bool _hasSetNavIndex = false;

  @override
  void initState() {
    super.initState();
    homeController = Get.find<HomeController>();
    themeController = Get.find<ThemeController>();
    profileService = Get.find<ProfileService>();
    _initializePrefs();

    // Refresh profile data when screen is loaded
    profileService.refreshProfile();

    if (!widget.isEmbeddedInMain) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasSetNavIndex && homeController.selectedNavIndex.value != 3) {
          homeController.selectedNavIndex.value = 3;
          _hasSetNavIndex = true;
        }
      });
    }
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final scaffold = Scaffold(
      backgroundColor: themeController.isDarkModeActive
          ? Color(0xFF121212)
          : Colors.white,
      appBar: AppBar(
        backgroundColor: themeController.isDarkModeActive
            ? Color(0xFF1E1E1E)
            : Colors.white,
        elevation: 0,
        leading: widget.isEmbeddedInMain
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: themeController.isDarkModeActive
                      ? Colors.white
                      : Colors.black,
                  size: screenWidth * 0.05,
                ),
                onPressed: () {
                  homeController.setNavIndex(0);
                  Get.toNamed(AppRoutes.mainHome);
                },
              ),
        automaticallyImplyLeading: !widget.isEmbeddedInMain,
        title: Text(
          'settings'.tr,
          style: TextStyle(
            color: themeController.isDarkModeActive ? Colors.white : Colors.black,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  MediaQuery.of(context).padding.top -
                  kBottomNavigationBarHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  // Profile Section
                  Obx(() {
                    print(
                      '📸 UI Update - Name: ${profileService.userName.value}, Image: ${profileService.profileImage.value}',
                    );
                    final version = profileService.imageVersion.value;
                    return Column(
                      children: [
                        Container(
                          width: screenWidth * 0.22,
                          height: screenWidth * 0.22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeController.isDarkModeActive
                                ? Color(0xFF1E1E1E)
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.11,
                            ),
                            child: profileService.profileImage.value.isNotEmpty
                                ? Image.network(
                                    profileService.getFullImageUrl(),
                                    key: Key('settings_profile_image_$version'),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('❌ Image load error: $error');
                                      return Image.asset(
                                        'assets/images/Ellipse 5.png',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    'assets/images/Ellipse 5.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          profileService.userName.value,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w600,
                            color: themeController.isDarkModeActive
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    );
                  }),
                  SizedBox(height: screenHeight * 0.04),

                  // Settings Options
                  _buildSettingsItem(
                    'user_profile'.tr,
                    'user_profile_subtitle'.tr,
                    'assets/icons/user.png',
                    () => Get.toNamed(AppRoutes.personalInformation),
                    screenWidth,
                    screenHeight,
                    themeController.isDarkModeActive,
                  ),
                  _buildSettingsItem(
                    'premium_plans'.tr,
                    'premium_plans_subtitle'.tr,
                    'assets/icons/PremiumPlans.png',
                    () => Get.toNamed(AppRoutes.premiumPlans),
                    screenWidth,
                    screenHeight,
                    themeController.isDarkModeActive,
                  ),
                  _buildSettingsItem(
                    'notification_setting'.tr,
                    'notification_setting_subtitle'.tr,
                    'assets/icons/NotificationSetting.png',
                    () => Get.toNamed(AppRoutes.notificationSettings),
                    screenWidth,
                    screenHeight,
                    themeController.isDarkModeActive,
                  ),
                  _buildSettingsItem(
                    'language'.tr,
                    'language_subtitle'.tr,
                    'assets/icons/Language.png',
                    () => Get.toNamed(AppRoutes.languageSettings),
                    screenWidth,
                    screenHeight,
                    themeController.isDarkModeActive,
                  ),
                  _buildSettingsItem(
                    'app_unlock'.tr,
                    'app_unlock_subtitle'.tr,
                    'assets/icons/AppUnlock.png',
                    () => Get.toNamed(AppRoutes.appUnlock),
                    screenWidth,
                    screenHeight,
                    themeController.isDarkModeActive,
                  ),
                  _buildSettingsItem(
                    'appearance'.tr,
                    'appearance_subtitle'.tr,
                    'assets/icons/Appearance.png',
                    () => Get.toNamed(AppRoutes.appearance),
                    screenWidth,
                    screenHeight,
                    themeController.isDarkModeActive,
                  ),
                  _buildSettingsItem(
                    'currency_change'.tr,
                    'currency_change_subtitle'.tr,
                    'assets/icons/Currency.png',
                    () => Get.toNamed(AppRoutes.currencyChange),
                    screenWidth,
                    screenHeight,
                    themeController.isDarkModeActive,
                  ),
                  _buildSettingsItem(
                    'Privacy Policy',
                    'Read privacy policy for data handling',
                    'assets/icons/Terms & Conditions.png',
                    () async {
                      final cfg = Get.find<ConfigService>();
                      final uri = Uri.parse(cfg.privacyPolicyUrl);
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    screenWidth,
                    screenHeight,
                    themeController.isDarkModeActive,
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    margin: EdgeInsets.only(bottom: screenHeight * 0.03),
                    child: OutlinedButton(
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            backgroundColor: themeController.isDarkModeActive
                                ? Color(0xFF1E1E1E)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              'logout'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: themeController.isDarkModeActive
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            content: Text(
                              'logout_confirmation'.tr,
                              style: TextStyle(
                                color: themeController.isDarkModeActive
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text(
                                  'cancel'.tr,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Get.back();
                                  homeController.logout();
                                },
                                child: Text(
                                  'logout'.tr,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: const Color(0xFF2196F3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                        backgroundColor: themeController.isDarkModeActive
                            ? Color(0xFF1E1E1E)
                            : Colors.white,
                      ),
                      child: Text(
                        'logout'.tr,
                        style: TextStyle(
                          color: const Color(0xFF2196F3),
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );

    if (widget.isEmbeddedInMain) {
      return scaffold;
    }

    return WillPopScope(
      onWillPop: () async {
        try {
          final prev = Get.previousRoute;
          int idx = 0;
          switch (prev) {
            case AppRoutes.mainHome:
              idx = 0;
              break;
            case AppRoutes.analytics:
              idx = 1;
              break;
            case AppRoutes.comparison:
              idx = 2;
              break;
            default:
              idx = 0;
          }
          homeController.setNavIndex(idx);
        } catch (_) {}
        return true;
      },
      child: scaffold,
    );
  }

  Widget _buildSettingsItem(
    String title,
    String subtitle,
    String iconPath,
    VoidCallback onTap,
    double screenWidth,
    double screenHeight,
    bool isDarkMode,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Color(0xFF2D2D2D)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Center(
                    child: Image.asset(
                      iconPath,
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: screenWidth * 0.04,
                  color: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
