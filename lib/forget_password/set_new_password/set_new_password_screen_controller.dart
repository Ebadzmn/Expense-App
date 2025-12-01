import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/forget_password/forgot_password_api_service.dart';
import '../../Settings/appearance/ThemeController.dart';
import 'package:your_expense/services/token_service.dart';


class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  _SetNewPasswordScreenState createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final themeController = Get.find<ThemeController>();
  final RxBool _isSubmitting = false.obs;
  late final String? _token;

  @override
  void initState() {
    super.initState();
    _token = (Get.arguments is Map) ? (Get.arguments as Map)['token']?.toString() : null;
    if (_token == null || _token!.isEmpty) {
      try {
        final tokenService = Get.isRegistered<TokenService>() ? Get.find<TokenService>() : null;
        if (tokenService != null) {
          _token = tokenService.getResetToken();
        }
      } catch (e) {
        print('⚠️ Failed to read reset token from storage: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkModeActive;

      return Scaffold(
        backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios,
                color: isDarkMode ? Colors.white : Colors.black,
                size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'new_password'.tr,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Lock Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/locks.png',
                          width: 40,
                          height: 40,
                          color: isDarkMode ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Center(
                    child: Text(
                      'set_new_password'.tr,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Center(
                    child: Text(
                      'enter_new_password'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Color(0xFFA0A0A0) : Color(0xFF6B7280),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Password Field
                  Text(
                    'password'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'enter_password'.tr,
                      hintStyle: TextStyle(
                        color: isDarkMode ? Color(0xFF757575) : Color(0xFF9CA3AF),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode ? Color(0xFF424242) : Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode ? Color(0xFF424242) : Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF2196F3),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Confirm Password Field
                  Text(
                    'confirm_password'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'confirm_your_password'.tr,
                      hintStyle: TextStyle(
                        color: isDarkMode ? Color(0xFF757575) : Color(0xFF9CA3AF),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode ? Color(0xFF424242) : Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode ? Color(0xFF424242) : Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF2196F3),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting.value ? null : () async {
                        final newPassword = _passwordController.text;
                        final confirmPassword = _confirmPasswordController.text;
                        if (newPassword.isEmpty || confirmPassword.isEmpty) {
                          Get.snackbar('Error'.tr, 'Please fill in all fields'.tr,
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        if (newPassword != confirmPassword) {
                          Get.snackbar('Error'.tr, 'Passwords do not match'.tr,
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        if (_token == null || _token!.isEmpty) {
                          Get.snackbar('Error'.tr, 'Token missing. Please verify OTP again.'.tr,
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        _isSubmitting.value = true;
                        try {
                          final service = Get.isRegistered<ForgotPasswordApiService>()
                              ? Get.find<ForgotPasswordApiService>()
                              : Get.put(ForgotPasswordApiService());
                          await service.init();
                          final resp = await service.resetPassword(
                            token: _token!,
                            newPassword: newPassword,
                            confirmPassword: confirmPassword,
                          );
                          final success = resp['success'] == true;
                          final message = resp['message']?.toString() ?? (success ? 'Password reset' : 'Reset failed');
                          if (success) {
                            Get.snackbar('Success'.tr, message, snackPosition: SnackPosition.BOTTOM);
                            // Clear stored reset token after successful reset
                            try {
                              final tokenService = Get.isRegistered<TokenService>() ? Get.find<TokenService>() : null;
                              await tokenService?.clearResetToken();
                            } catch (e) {
                              print('⚠️ Failed to clear reset token: $e');
                            }
                            Get.offAllNamed('/login');
                          } else {
                            Get.snackbar('Error'.tr, message, snackPosition: SnackPosition.BOTTOM);
                          }
                        } catch (e) {
                          Get.snackbar('Error'.tr, e.toString().replaceAll('Exception: ', ''),
                              snackPosition: SnackPosition.BOTTOM);
                        } finally {
                          _isSubmitting.value = false;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Obx(() => _isSubmitting.value
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'continue'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            )),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}