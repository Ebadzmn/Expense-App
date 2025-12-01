// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/routes/app_routes.dart';
import 'package:your_expense/text_styles.dart';

import '../../Settings/appearance/ThemeController.dart';
import '../../colors/app_colors.dart';
import 'login_controller.dart';


class LoginScreen extends GetView<LoginController> {
  final RxBool isPasswordVisible = false.obs;

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() => Scaffold(
      backgroundColor: themeController.isDarkModeActive
          ? const Color(0xFF121212)
          : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo Image
              Center(
                child: Image.asset(
                  'assets/images/fileimage.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'welcomeBack'.tr,
                style: AppTextStyles.heading1.copyWith(
                  color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'loginToAccount'.tr,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: themeController.isDarkModeActive ? Colors.grey[400] : AppColors.text500,
                ),
              ),
              const SizedBox(height: 40),

              // Error message
              Obx(() => controller.errorMessage.value.isNotEmpty
                  ? Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[800], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink()),

              // Email Field
              Text('email'.tr, style: AppTextStyles.inputLabel.copyWith(
                color: themeController.isDarkModeActive ? Colors.white : Colors.black,
              )),
              const SizedBox(height: 8),
              TextField(
                controller: controller.emailController,
                decoration: InputDecoration(
                  hintText: 'enterEmail'.tr,
                  hintStyle: AppTextStyles.inputHint.copyWith(
                    color: themeController.isDarkModeActive ? Colors.grey[500] : AppColors.text500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: themeController.isDarkModeActive ? Colors.grey[700]! : AppColors.text200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary500),
                  ),
                  filled: themeController.isDarkModeActive,
                  fillColor: themeController.isDarkModeActive ? const Color(0xFF1E1E1E) : Colors.transparent,
                ),
                style: AppTextStyles.inputText.copyWith(
                  color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Password Field
              Text('password'.tr, style: AppTextStyles.inputLabel.copyWith(
                color: themeController.isDarkModeActive ? Colors.white : Colors.black,
              )),
              const SizedBox(height: 8),
              Obx(() => TextField(
                controller: controller.passwordController,
                obscureText: !isPasswordVisible.value,
                decoration: InputDecoration(
                  hintText: 'enterPassword'.tr,
                  hintStyle: AppTextStyles.inputHint.copyWith(
                    color: themeController.isDarkModeActive ? Colors.grey[500] : AppColors.text500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: themeController.isDarkModeActive ? Colors.grey[700]! : AppColors.text200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary500),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: themeController.isDarkModeActive ? Colors.grey[400] : AppColors.text400,
                    ),
                    onPressed: () => isPasswordVisible.toggle(),
                  ),
                  filled: themeController.isDarkModeActive,
                  fillColor: themeController.isDarkModeActive ? const Color(0xFF1E1E1E) : Colors.transparent,
                ),
                style: AppTextStyles.inputText.copyWith(
                  color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                ),
              )),
              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.forgetPassword);
                  },
                  child: Text(
                    'forgotPassword'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button with Face ID
              Row(
                children: [
                  Expanded(
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                        controller.login();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text('login'.tr, style: AppTextStyles.buttonLarge),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeController.isDarkModeActive ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border.all(
                        color: themeController.isDarkModeActive ? Colors.grey[700]! : AppColors.text200,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Use push so user can go back to Login
                        Get.toNamed(AppRoutes.faceLogin);
                      },
                      icon: Image.asset(
                        'assets/icons/face.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Guest Login Link
              Center(
                child: TextButton(
                  onPressed: () {
                    controller.loginAsGuest();
                  },
                  child: Text(
                    'loginAsGuest'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Social login UI removed
              const SizedBox.shrink(),

              // Register Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.register);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "noAccount".tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: themeController.isDarkModeActive ? Colors.grey[400] : AppColors.text500,
                      ),
                      children: [
                        TextSpan(
                          text: 'register'.tr,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}