import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../appearance/ThemeController.dart';
import '../../services/face_id_service.dart';
import '../../services/local_auth_service.dart';

class AppUnlockScreen extends StatefulWidget {
  const AppUnlockScreen({super.key});

  @override
  _AppUnlockScreenState createState() => _AppUnlockScreenState();
}

class _AppUnlockScreenState extends State<AppUnlockScreen> {
  String selectedOption = 'none'; // Default selection
  bool enableFaceID = true;
  bool faceIDForAppLaunch = true;

  late final FaceIdService _faceService;
  late final LocalAuthService _localAuth;

  @override
  void initState() {
    super.initState();
    _faceService = Get.isRegistered<FaceIdService>()
        ? Get.find<FaceIdService>()
        : Get.put(FaceIdService(), permanent: true);
    _localAuth = Get.isRegistered<LocalAuthService>()
        ? Get.find<LocalAuthService>()
        : Get.put(LocalAuthService(), permanent: true);
    // Initialize toggle state from saved preference
    enableFaceID = _faceService.isEnabledForCurrentUser();
    faceIDForAppLaunch = _faceService.isLaunchGateEnabledForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Obx(() => Scaffold(
      backgroundColor: themeController.isDarkModeActive
          ? const Color(0xFF121212)
          : Colors.white,
      appBar: AppBar(
        backgroundColor: themeController.isDarkModeActive
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: themeController.isDarkModeActive ? Colors.white : Colors.black,
            size: screenWidth * 0.05,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'app_unlock'.tr,
          style: TextStyle(
            color: themeController.isDarkModeActive ? Colors.white : Colors.black,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            children: [
              

  

              SizedBox(height: screenHeight * 0.04),

              // Security Settings Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'security_settings'.tr,
                  style: TextStyle(
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.w600,
                    color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Enable FaceID Setting
              _buildSecuritySetting(
                'enable_faceid'.tr,
                'enable_faceid_desc'.tr,
                'assets/icons/enabalfaceid.png',
                enableFaceID,
                (value) async {
                  // Handle enable/disable with service and biometric support
                  if (value) {
                    final supported = await _localAuth.isSupported();
                    if (!supported) {
                      if (mounted) {
                        setState(() {
                          enableFaceID = false;
                        });
                      }
                      Get.snackbar(
                        'Face ID unavailable',
                        'Your device does not support biometrics.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade800,
                      );
                      return;
                    }
                    try {
                      await _faceService.enableForCurrentUser();
                      if (mounted) {
                        setState(() {
                          enableFaceID = true;
                        });
                      }
                      Get.snackbar(
                        'Enabled',
                        'Face ID enabled for your account.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.shade100,
                        colorText: Colors.green.shade800,
                      );
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          enableFaceID = false;
                        });
                      }
                      Get.snackbar(
                        'Error',
                        'Could not enable Face ID. Please try again.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade800,
                      );
                    }
                  } else {
                    try {
                      await _faceService.disableForCurrentUser();
                      if (mounted) {
                        setState(() {
                          enableFaceID = false;
                        });
                      }
                      Get.snackbar(
                        'Disabled',
                        'Face ID disabled for your account.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange.shade100,
                        colorText: Colors.orange.shade800,
                      );
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          enableFaceID = true;
                        });
                      }
                      Get.snackbar(
                        'Error',
                        'Could not disable Face ID. Please try again.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade800,
                      );
                    }
                  }
                },
                screenWidth,
                screenHeight,
                themeController.isDarkModeActive,
              ),

              // FaceID for App Launch Setting
              _buildSecuritySetting(
                'faceid_app_launch'.tr,
                'faceid_app_launch_desc'.tr,
                'assets/icons/rocket.png',
                faceIDForAppLaunch,
                (value) async {
                  // Persist app-launch gate preference; require biometrics support when enabling
                  if (value) {
                    final supported = await _localAuth.isSupported();
                    if (!supported) {
                      if (mounted) setState(() { faceIDForAppLaunch = false; });
                      Get.snackbar(
                        'Face ID unavailable',
                        'Your device does not support biometrics.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade800,
                      );
                      return;
                    }
                  }
                  try {
                    await _faceService.setLaunchGateForCurrentUser(value);
                    if (mounted) setState(() { faceIDForAppLaunch = value; });
                    Get.snackbar(
                      value ? 'Enabled' : 'Disabled',
                      value ? 'Face ID required on app launch.' : 'Face ID not required on launch.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: value ? Colors.green.shade100 : Colors.orange.shade100,
                      colorText: value ? Colors.green.shade800 : Colors.orange.shade800,
                    );
                  } catch (e) {
                    if (mounted) setState(() { faceIDForAppLaunch = !value; });
                    Get.snackbar(
                      'Error',
                      'Could not update app-launch Face ID setting.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.shade100,
                      colorText: Colors.red.shade800,
                    );
                  }
                },
                screenWidth,
                screenHeight,
                themeController.isDarkModeActive,
              ),

              SizedBox(height: screenHeight * 0.03),

              // Info Message
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: themeController.isDarkModeActive
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: themeController.isDarkModeActive
                          ? Colors.grey[400]
                          : const Color(0xFF6B7280),
                      size: screenWidth * 0.05,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        'security_info'.tr,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: themeController.isDarkModeActive
                              ? Colors.grey[400]
                              : const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildUnlockOptionCard(
      String title,
      String subtitle,
      String iconPath,
      String value,
      Color iconColor,
      double screenWidth,
      double screenHeight,
      bool isDarkMode, {
        VoidCallback? onTap,
      }) {
    bool isSelected = selectedOption == value;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {
            setState(() {
              selectedOption = value;
            });
          },
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.025,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: isSelected
                  ? Border.all(color: const Color(0xFF2196F3), width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Center(
                    child: Image.asset(
                      iconPath,
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                      color: iconColor,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),

                // Text Content
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
                          color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: screenWidth * 0.04,
                  color: isDarkMode ? Colors.grey[400] : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySetting(
      String title,
      String subtitle,
      String iconPath,
      bool value,
      Function(bool) onChanged,
      double screenWidth,
      double screenHeight,
      bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),

          // Text Content
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
                    color: isDarkMode ? Colors.grey[400] : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Toggle Switch
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2196F3),
            activeTrackColor: const Color(0xFF2196F3).withOpacity(0.3),
            inactiveThumbColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            inactiveTrackColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}