// controllers/login_controller.dart
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_expense/Analytics/expense_controller.dart';

import '../../routes/app_routes.dart';

import 'package:your_expense/Settings/userprofile/profile_services.dart';

import '../home/home_controller.dart';
import 'login_service.dart';
import 'package:your_expense/services/subscription_service.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  SharedPreferences? _prefs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  void login() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final email = emailController.text.trim();
      final password = passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        errorMessage.value = 'Please fill in all fields';
        return;
      }

      if (!GetUtils.isEmail(email)) {
        errorMessage.value = 'Please enter a valid email address';
        return;
      }

      // Resolve LoginService lazily and ensure a non-null instance
      final LoginService loginService = Get.isRegistered<LoginService>()
          ? Get.find<LoginService>()
          : Get.put(LoginService());
      final response = await loginService.login(email, password);

      if (response['success'] == true) {
        // Immediately reconcile premium status with server after login (fresh installs included)
        try {
          await SubscriptionService.to.reconcileWithServer();
        } catch (_) {}

        // Token is saved via LoginService. Navigate and ensure home data is loaded.
        Get.offNamed(AppRoutes.mainHome);
        try {
          final home = Get.find<HomeController>();
          home.reset();
          await home.ensureHomeDataLoaded();
        } catch (_) {}
        // Reset expenses to avoid showing stale data from previous session
        try {
          final exp = Get.find<ExpenseController>();
          exp.reset();
          await exp.loadExpenses();
        } catch (_) {}
        // Refresh profile so personal info shows correct name/email immediately
        try {
          final profile = Get.find<ProfileService>();
          await profile.fetchUserProfile(forceRefresh: true);
        } catch (_) {}
      } else {
        errorMessage.value = response['message']?.toString() ?? 'Login failed';
      }
    } catch (e) {
      // Display user-friendly error messages
      final errorString = e.toString();

      if (errorString.contains("User doesn't exist") ||
          errorString.contains("User not found")) {
        errorMessage.value =
            'User not found. Please check your email or register for an account.';
      } else if (errorString.contains("Invalid email or password") ||
          errorString.contains("Invalid credentials")) {
        errorMessage.value = 'Invalid email or password. Please try again.';
      } else if (errorString.contains("Unauthorized")) {
        errorMessage.value = 'Access denied. Please try again.';
      } else if (errorString.contains("Server error")) {
        errorMessage.value = 'Server error. Please try again later.';
      } else if (errorString.contains("Network")) {
        errorMessage.value =
            'Network error. Please check your internet connection.';
      } else {
        errorMessage.value = 'Login failed. Please try again.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  void loginAsGuest() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Guest should not see previous user data; show empty state
      Get.offNamed(AppRoutes.mainHome);
      try {
        final home = Get.find<HomeController>();
        home.reset();
      } catch (_) {}
      try {
        final exp = Get.find<ExpenseController>();
        exp.reset();
      } catch (_) {}
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() {
    errorMessage.value = '';
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
