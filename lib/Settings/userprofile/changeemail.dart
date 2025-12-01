import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../appearance/ThemeController.dart';
import '../../services/api_base_service.dart';
import '../../services/config_service.dart';

import 'package:your_expense/Settings/userprofile/profile_services.dart';

import 'change_email_service.dart';

class ChangeEmailScreen extends StatelessWidget {
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController confirmEmailController = TextEditingController();
  final TextEditingController otpController1 = TextEditingController();
  final TextEditingController otpController2 = TextEditingController();
  final TextEditingController otpController3 = TextEditingController();
  final TextEditingController otpController4 = TextEditingController();
  final ThemeController themeController = Get.find<ThemeController>();
  final ApiBaseService apiService = Get.find<ApiBaseService>();
  final ConfigService configService = Get.find<ConfigService>();
  final ChangeEmailService changeEmailService = Get.find<ChangeEmailService>();
  final ProfileService profileService = Get.find<ProfileService>();
  final RxBool isLoading = false.obs;
  final RxBool isOtpSent = false.obs;

  Future<void> _sendOtp() async {
    try {
      isLoading.value = true;
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      if (newEmailController.text.isEmpty || confirmEmailController.text.isEmpty) {
        Get.back();
        isLoading.value = false;
        Get.snackbar(
          'error'.tr,
          'fill_all_fields'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (newEmailController.text != confirmEmailController.text) {
        Get.back();
        isLoading.value = false;
        Get.snackbar(
          'error'.tr,
          'email_mismatch'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Ensure we have the current email loaded
      if (profileService.email.value.isEmpty) {
        try { await profileService.fetchUserProfile(); } catch (_) {}
      }

      // Send OTP to the CURRENT email to verify identity
      await apiService.request(
        'POST',
        '${configService.baseUrl}/user/send-otp',
        body: {'email': profileService.email.value},
        requiresAuth: false,
      );

      Get.back();
      isLoading.value = false;
      isOtpSent.value = true;

      Get.snackbar(
        'otp_sent'.tr,
        'otp_sent_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: themeController.isDarkModeActive
            ? Color(0xFF2D2D2D)
            : Color(0xFF2196F3),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      isLoading.value = false;
      Get.snackbar(
        'error'.tr,
        'otp_send_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('❌ OTP Send Error: $e');
    }
  }

  Future<void> _resendOtp() async {
    try {
      isLoading.value = true;
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Ensure we have the current email loaded
      if (profileService.email.value.isEmpty) {
        try { await profileService.fetchUserProfile(); } catch (_) {}
      }

      await apiService.request(
        'POST',
        '${configService.baseUrl}/user/send-otp',
        body: {'email': profileService.email.value},
        requiresAuth: false,
      );

      Get.back();
      isLoading.value = false;

      Get.snackbar(
        'otp_resent'.tr,
        'otp_resent_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: themeController.isDarkModeActive
            ? Color(0xFF2D2D2D)
            : Color(0xFF2196F3),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      isLoading.value = false;
      Get.snackbar(
        'error'.tr,
        'otp_resend_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('❌ OTP Resend Error: $e');
    }
  }

  Future<void> _changeEmail() async {
    try {
      isLoading.value = true;
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final otp = int.parse('${otpController1.text}${otpController2.text}${otpController3.text}${otpController4.text}');

      // Ensure current email is ready
      if (profileService.email.value.isEmpty) {
        try { await profileService.fetchUserProfile(); } catch (_) {}
      }

      await apiService.request(
        'PATCH',
        '${configService.baseUrl}/user/change-email',
        body: {
          'currentEmail': profileService.email.value,
          'newEmail': newEmailController.text,
          'otp': otp,
        },
        requiresAuth: true,
      );

      Get.back();
      isLoading.value = false;

      // Update local states and refresh profile
      try { await changeEmailService.updateEmail(newEmailController.text); } catch (_) {}
      profileService.email.value = newEmailController.text;
      try { await profileService.fetchUserProfile(forceRefresh: true); } catch (_) {}

      Get.snackbar(
        'email_changed'.tr,
        'email_changed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: themeController.isDarkModeActive
            ? Color(0xFF2D2D2D)
            : Color(0xFF2196F3),
        colorText: Colors.white,
      );

      Get.offAllNamed('/settings/personal-information');
    } catch (e) {
      Get.back();
      isLoading.value = false;
      Get.snackbar(
        'error'.tr,
        'email_change_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('❌ Email Change Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: themeController.isDarkModeActive ? Color(0xFF121212) : Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: themeController.isDarkModeActive ? Color(0xFF1E1E1E) : Color(0xFFF8F9FA),
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
          'change_email'.tr,
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
              SizedBox(height: screenHeight * 0.08),
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  color: themeController.isDarkModeActive
                      ? Color(0xFF2D2D2D)
                      : const Color(0xFF2196F3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: screenWidth * 0.08,
                  color: const Color(0xFF2196F3),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Text(
                'email_change_description'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: themeController.isDarkModeActive ? Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'new_email'.tr,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: newEmailController,
                    style: TextStyle(
                      color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'email_example'.tr,
                      hintStyle: TextStyle(
                        color: themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade400,
                        fontSize: screenWidth * 0.035,
                      ),
                      filled: true,
                      fillColor: themeController.isDarkModeActive ? Color(0xFF1E1E1E) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: themeController.isDarkModeActive ? Color(0xFF3A3A3A) : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: themeController.isDarkModeActive ? Color(0xFF3A3A3A) : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: const Color(0xFF2196F3)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.018,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'confirm_email'.tr,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: confirmEmailController,
                    style: TextStyle(
                      color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'email_example'.tr,
                      hintStyle: TextStyle(
                        color: themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade400,
                        fontSize: screenWidth * 0.035,
                      ),
                      filled: true,
                      fillColor: themeController.isDarkModeActive ? Color(0xFF1E1E1E) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: themeController.isDarkModeActive ? Color(0xFF3A3A3A) : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: themeController.isDarkModeActive ? Color(0xFF3A3A3A) : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: const Color(0xFF2196F3)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.018,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.04),
              Obx(() => !isOtpSent.value
                  ? Container(
                width: double.infinity,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  onPressed: _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'send_otp'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'enter_otp'.tr,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildOtpField(otpController1, screenWidth, screenHeight, themeController.isDarkModeActive),
                      _buildOtpField(otpController2, screenWidth, screenHeight, themeController.isDarkModeActive),
                      _buildOtpField(otpController3, screenWidth, screenHeight, themeController.isDarkModeActive),
                      _buildOtpField(otpController4, screenWidth, screenHeight, themeController.isDarkModeActive),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  GestureDetector(
                    onTap: _resendOtp,
                    child: Text(
                      'dont_get_code_resend'.tr,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: const Color(0xFF2196F3),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Container(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      onPressed: _changeEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'submit'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )),
              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(
      TextEditingController controller,
      double screenWidth,
      double screenHeight,
      bool isDarkMode,
      ) {
    return Container(
      width: screenWidth * 0.15,
      child: TextField(
        controller: controller,
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: screenWidth * 0.05,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            borderSide: BorderSide(color: isDarkMode ? Color(0xFF3A3A3A) : Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            borderSide: BorderSide(color: isDarkMode ? Color(0xFF3A3A3A) : Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            borderSide: BorderSide(color: const Color(0xFF2196F3)),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.015,
          ),
        ),
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(Get.context!).nextFocus();
          }
        },
      ),
    );
  }
}