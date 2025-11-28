import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/RegisterScreen/registration_api_service.dart';
import 'dart:convert';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/token_service.dart';
import 'package:your_expense/services/push_notification_service.dart';

class RegistrationController extends GetxController {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  late final RegistrationApiService _registrationApiService;

  var isTermsAccepted = false.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('📋 RegistrationController initialized');
    _registrationApiService = Get.isRegistered<RegistrationApiService>()
        ? Get.find<RegistrationApiService>()
        : Get.put(RegistrationApiService(), permanent: true);
    _registrationApiService.init();
  }

  void toggleTermsAccepted(bool? value) {
    if (value != null) {
      isTermsAccepted.value = value;
      print('📋 Terms accepted: $value');
    }
  }

  Future<bool> registerUser() async {
    print('=== Starting registerUser ===');
    print('📋 Full name: "${fullNameController.text.trim()}"');
    print('📋 Email: "${emailController.text.trim()}"');
    print('📋 Password length: ${passwordController.text.length}');
    print('📋 Terms accepted: ${isTermsAccepted.value}');

    if (!validateForm()) {
      print('❌ Validation failed');
      return false;
    }
    print('✅ Validation passed');

    isLoading.value = true;

    try {
      // Try to get FCM token from PushNotificationService
      String? fcmToken;
      try {
        final notificationService = Get.isRegistered<PushNotificationService>()
            ? Get.find<PushNotificationService>()
            : null;
        fcmToken = notificationService?.getToken();
        print('📲 Resolved FCM token for registration: ${fcmToken ?? 'null'}');
      } catch (e) {
        print('⚠️ Unable to get FCM token before registration: $e');
      }

      final userData = {
        "name": fullNameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "preferredLanguage": "English",
        "contact": "",
        "role": "USER"
      };

      // Attach FCM token if available
      if (fcmToken != null && fcmToken.isNotEmpty) {
        userData['fcmToken'] = fcmToken;
      }
      print('📤 Sending request with body: $userData');

      final response = await _registrationApiService.registerUser(userData);
      print('📥 Full API response: $response');
      print('📥 Response type: ${response.runtimeType}');
      print('📥 Success field: ${response['success']}');
      print('📥 Data field: ${response['data']}');
      print('📥 Data type: ${response['data']?.runtimeType}');

      isLoading.value = false;

      // Check if registration was successful
      if (response['success'] == true && response['data'] != null) {
        print('✅ Registration successful!');
        print('📦 User data received: ${response['data']}');

        // Check if there's a token in the response
        // The API might return token in different places
        String? token;

        if (response['token'] != null) {
          token = response['token'].toString();
          print('🔑 Token found in response[token]');
        } else if (response['data'] is String && response['data'].toString().contains('.')) {
          // Check if data itself is a JWT token (contains dots)
          token = response['data'].toString();
          print('🔑 Token found in response[data] as string');
        } else if (response['data'] is Map && response['data']['token'] != null) {
          token = response['data']['token'].toString();
          print('🔑 Token found in response[data][token]');
        } else {
          print('ℹ️ No token in registration response');
          print('ℹ️ This is normal - token will be provided after email verification');
        }

        // Save token if available
        if (token != null && token.isNotEmpty) {
          final ts = await _ensureTokenServiceReady();
          await ts.saveToken(token);
          print('✅ Token saved successfully');

          final savedToken = ts.getToken();
          print('📋 Verified saved token exists: ${savedToken != null}');
        }

        showSuccessSnackbar('Success'.tr, 'Registration successful! Please verify your email.'.tr);
        print('🎉 Registration complete, returning true');

        // Add a small delay to ensure snackbar is visible
        await Future.delayed(Duration(milliseconds: 500));

        return true;
      } else {
        print('❌ API returned success=false or no data: $response');
        handleApiError(response);
        return false;
      }
    } on HttpException catch (e) {
      print('❌ HttpException caught');
      print('❌ Status code: ${e.statusCode}');
      print('❌ Message: ${e.message}');

      isLoading.value = false;

      if (e.statusCode == 400 || e.statusCode == 409) {
        try {
          final errorData = json.decode(e.message);
          print('📋 Parsed error data: $errorData');
          handleApiError(errorData);
        } catch (parseError) {
          print('❌ Error parsing HttpException message: $parseError');
          showErrorSnackbar('Registration Error'.tr, 'Failed to register. Please try again.'.tr);
        }
      } else {
        showErrorSnackbar('Registration Error'.tr, 'Failed to register. Please try again.'.tr);
      }
      return false;
    } catch (e, stackTrace) {
      print('❌ General error caught: $e');
      print('❌ Stack trace: $stackTrace');

      isLoading.value = false;
      showErrorSnackbar('Network Error'.tr, 'Please check your internet connection'.tr);
      return false;
    }
  }

  void handleApiError(Map<String, dynamic> response) {
    final errorMessage = response['message'] ?? 'Unknown error occurred';
    print('❌ Handling API error: $errorMessage');
    print('📋 Full error response: $response');

    if (errorMessage.toString().toLowerCase().contains('email already exist')) {
      showErrorSnackbar('Registration Error'.tr, 'This email is already registered. Please login or use a different email.'.tr);
    } else if (errorMessage.toString().toLowerCase().contains('already registered')) {
      showErrorSnackbar('Registration Error'.tr, 'This email is already registered. Please login.'.tr);
    } else if (response['errorMessages'] != null) {
      final errors = response['errorMessages'] as List;
      if (errors.isNotEmpty) {
        final firstError = errors[0];
        final errorText = firstError['message'] ?? errorMessage;
        showErrorSnackbar('Validation Error'.tr, errorText.toString());
      } else {
        showErrorSnackbar('Registration Error'.tr, errorMessage.toString());
      }
    } else {
      showErrorSnackbar('Registration Error'.tr, errorMessage.toString());
    }
  }

  bool validateForm() {
    String? errorMsg;

    if (fullNameController.text.trim().isEmpty) {
      errorMsg = 'Please enter your full name'.tr;
    } else if (fullNameController.text.trim().length < 2) {
      errorMsg = 'Name must be at least 2 characters long'.tr;
    } else if (emailController.text.trim().isEmpty) {
      errorMsg = 'Please enter your email address'.tr;
    } else if (!GetUtils.isEmail(emailController.text.trim())) {
      errorMsg = 'Please enter a valid email address'.tr;
    } else if (passwordController.text.isEmpty) {
      errorMsg = 'Please create a password'.tr;
    } else if (passwordController.text.length < 6) {
      errorMsg = 'Password must be at least 6 characters long'.tr;
    } else if (confirmPasswordController.text.isEmpty) {
      errorMsg = 'Please confirm your password'.tr;
    } else if (passwordController.text != confirmPasswordController.text) {
      errorMsg = 'Passwords do not match'.tr;
    }

    if (errorMsg != null) {
      print('❌ Validation error: $errorMsg');
      showErrorSnackbar('Validation Error'.tr, errorMsg);
      return false;
    }
    print('✅ Form validation passed');
    return true;
  }

  void showErrorSnackbar(String title, String message) {
    final isDarkMode = Get.isDarkMode;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isDarkMode ? Colors.red[800] : Colors.red[100],
      colorText: isDarkMode ? Colors.white : Colors.red[900],
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 4),
      icon: Icon(Icons.error_outline, color: isDarkMode ? Colors.white : Colors.red[900]),
    );
  }

  void showSuccessSnackbar(String title, String message) {
    final isDarkMode = Get.isDarkMode;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isDarkMode ? Colors.green[800] : Colors.green[100],
      colorText: isDarkMode ? Colors.white : Colors.green[900],
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
      icon: Icon(Icons.check_circle_outline, color: isDarkMode ? Colors.white : Colors.green[900]),
    );
  }

  void clearForm() {
    fullNameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    isTermsAccepted.value = false;
    print('📋 Form cleared');
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    print('🗑️ RegistrationController disposed');
    super.onClose();
  }

  int min(int a, int b) => a < b ? a : b;
}
  Future<TokenService> _ensureTokenServiceReady() async {
    if (Get.isRegistered<TokenService>()) {
      final ts = Get.find<TokenService>();
      if (ts.isInitialized.value != true) {
        await ts.init();
      }
      return ts;
    } else {
      final ts = Get.put(TokenService());
      await ts.init();
      return ts;
    }
  }