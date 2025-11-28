import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'verification_api_service.dart';
import 'package:your_expense/login/login_service.dart';
import 'package:your_expense/services/subscription_service.dart';
import '../routes/app_routes.dart';

class VerificationController extends GetxController {
  VerificationApiService _getVerificationService() {
    return Get.isRegistered<VerificationApiService>()
        ? Get.find<VerificationApiService>()
        : Get.put(VerificationApiService(), permanent: true);
  }
  final String? email = Get.arguments?['email'];

  List<TextEditingController> otpControllers = List.generate(
    4,
        (index) => TextEditingController(),
  );

  var isVerifyEnabled = false.obs;
  var canResend = true.obs;
  var resendCountdown = 10.obs;
  var isVerifying = false.obs; // Add loading state for verification

  Timer? _countdownTimer;

  @override
  Future<void> onInit() async {
    super.onInit();

    print('═══════════════════════════════════════');
    print('📋 VERIFICATION CONTROLLER INITIALIZED');
    print('📧 Email from arguments: $email');
    print('═══════════════════════════════════════');

    if (email == null || email!.isEmpty) {
      print('❌ No email provided!');
      Get.snackbar(
        'Error',
        'No email provided. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(12),
      );
      Future.delayed(Duration(seconds: 1), () => Get.back());
      return;
    }

    for (int i = 0; i < otpControllers.length; i++) {
      otpControllers[i].addListener(() {
        checkVerifyButtonState();
      });
    }

    // Ensure we are not carrying over a previous logged-in user's state
    // during registration/OTP verification.
    try {
      if (Get.isRegistered<LoginService>()) {
        final ls = Get.find<LoginService>();
        if (ls.isLoggedIn.value) {
          print('⚠️ Logged-in state detected at OTP screen; forcing logout to avoid user mix-up');
          await ls.logout();
        }
      }
      if (Get.isRegistered<SubscriptionService>()) {
        await Get.find<SubscriptionService>().reset();
      }
    } catch (e) {
      print('Warn: failed to clean auth state at OTP init: $e');
    }

    final s = _getVerificationService();
    await s.init();
    startResendCountdown();
  }

  void startResendCountdown() {
    canResend.value = false;
    resendCountdown.value = 10;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (resendCountdown.value > 0) {
        resendCountdown.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  void onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 3) {
        FocusScope.of(Get.context!).nextFocus();
      }
    } else {
      if (index > 0) {
        FocusScope.of(Get.context!).previousFocus();
      }
    }
    checkVerifyButtonState();
  }

  void checkVerifyButtonState() {
    bool allFilled = otpControllers.every((controller) => controller.text.isNotEmpty);
    isVerifyEnabled.value = allFilled;
  }

  String getOtpCode() {
    return otpControllers.map((controller) => controller.text).join();
  }

  Future<void> verifyOtp() async {
    if (isVerifying.value) {
      print('⚠️ Verification already in progress, ignoring duplicate call');
      return;
    }

    if (email == null || email!.isEmpty) {
      print('❌ No email available for verification');
      Get.snackbar(
        'Error',
        'No email provided. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    String otpCode = getOtpCode();

    print('═══════════════════════════════════════');
    print('🔐 STARTING OTP VERIFICATION');
    print('📧 Email: $email');
    print('🔢 OTP Code: $otpCode');
    print('📏 OTP Length: ${otpCode.length}');
    print('═══════════════════════════════════════');

    if (otpCode.length != 4) {
      print('❌ Invalid OTP length');
      Get.snackbar(
        'Invalid Code',
        'Please enter a valid 4-digit verification code.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    // Ensure OTP contains only digits
    if (!RegExp(r'^\d{4}$').hasMatch(otpCode)) {
      print('❌ OTP contains non-digit characters');
      Get.snackbar(
        'Invalid Code',
        'Code must contain only digits.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    isVerifying.value = true;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: const Color(0xFF4A90E2),
                ),
                SizedBox(height: 16),
                Text(
                  'Verifying...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      print('🚀 Calling API: verifyEmail($email, $otpCode)');
      final int otpInt = int.parse(otpCode);
      final response = await _getVerificationService().verifyEmail(email!, otpInt);

      print('═══════════════════════════════════════');
      print('📨 API RESPONSE RECEIVED');
      print('✅ Success: ${response.success}');
      print('💬 Message: ${response.message}');
      print('📋 Error Messages: ${response.errorMessages}');
      print('═══════════════════════════════════════');

      Get.back(); // Close loading dialog
      isVerifying.value = false;

      if (response.success) {
        print('✅✅✅ VERIFICATION SUCCESSFUL ✅✅✅');

        Get.snackbar(
          'Success',
          'Email verified successfully!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          margin: const EdgeInsets.all(12),
          duration: Duration(seconds: 2),
          icon: Icon(Icons.check_circle, color: Colors.green[700]),
        );

        print('⏳ Waiting 800ms before navigation...');
        await Future.delayed(Duration(milliseconds: 800));

        print('🚀 Attempting navigation to /login');
        try {
          await Get.offAllNamed(AppRoutes.login);
          print('✅ Navigated to login page');
        } catch (navError) {
          print('❌ Navigation error: $navError');
          print('❌ Stack trace: ${StackTrace.current}');

          Get.snackbar(
            'Navigation Error',
            'Verification successful but could not navigate. Please restart the app.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange[100],
            colorText: Colors.orange[900],
            margin: const EdgeInsets.all(12),
            duration: Duration(seconds: 4),
          );
        }
      } else {
        print('❌ Verification failed');
        String errorMessage = response.message;

        if (response.errorMessages != null && response.errorMessages!.isNotEmpty) {
          errorMessage = response.errorMessages!.first.message;
          print('📋 Specific error: $errorMessage');
        }

        if (errorMessage.toLowerCase().contains('invalid') ||
            errorMessage.toLowerCase().contains('incorrect')) {
          errorMessage = 'Invalid verification code. Please check and try again.';
        } else if (errorMessage.toLowerCase().contains('expired')) {
          errorMessage = 'Verification code has expired. Please request a new one.';
        }

        Get.snackbar(
          'Verification Failed',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          margin: const EdgeInsets.all(12),
          duration: Duration(seconds: 4),
          icon: Icon(Icons.error_outline, color: Colors.red[700]),
        );

        for (var controller in otpControllers) {
          controller.clear();
        }
        checkVerifyButtonState();

        if (Get.context != null) {
          FocusScope.of(Get.context!).requestFocus(FocusNode());
        }
      }
    } catch (e, stackTrace) {
      Get.back();
      isVerifying.value = false;

      print('═══════════════════════════════════════');
      print('❌❌❌ VERIFICATION ERROR ❌❌❌');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('═══════════════════════════════════════');

      String errorMessage = 'Failed to verify OTP. Please try again.';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response from server. Please try again.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(12),
        duration: Duration(seconds: 4),
        icon: Icon(Icons.error_outline, color: Colors.red[700]),
      );
    }
  }

  Future<void> resendCode() async {
    if (!canResend.value) {
      print('⚠️ Cannot resend yet, countdown: ${resendCountdown.value}');
      return;
    }

    if (email == null || email!.isEmpty) {
      print('❌ No email available for resending');
      Get.snackbar(
        'Error',
        'No email provided. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(12),
      );
      return;
    }

    print('═══════════════════════════════════════');
    print('🔄 RESENDING OTP');
    print('📧 Email: $email');
    print('═══════════════════════════════════════');

    Get.dialog(
      Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF4A90E2),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      print('🚀 Calling API: resendOtp($email)');
      final response = await _getVerificationService().resendOtp(email!);

      print('═══════════════════════════════════════');
      print('📨 RESEND API RESPONSE');
      print('✅ Success: ${response.success}');
      print('💬 Message: ${response.message}');
      print('═══════════════════════════════════════');

      Get.back(); // Close loading dialog

      if (response.success) {
        print('✅ OTP resent successfully');

        // Clear OTP fields
        for (var controller in otpControllers) {
          controller.clear();
        }

        Get.snackbar(
          'Code Sent',
          response.message.isEmpty ? 'A new verification code has been sent to your email.' : response.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue[100],
          colorText: Colors.blue[900],
          margin: const EdgeInsets.all(12),
          duration: Duration(seconds: 3),
          icon: Icon(Icons.email_outlined, color: Colors.blue[700]),
        );

        checkVerifyButtonState();
        startResendCountdown();
      } else {
        print('❌ Resend failed');
        String errorMessage = response.message;

        if (response.errorMessages != null && response.errorMessages!.isNotEmpty) {
          errorMessage = response.errorMessages!.first.message;
        }

        if (errorMessage.isEmpty) {
          errorMessage = 'Failed to resend verification code. Please try again.';
        }

        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          margin: const EdgeInsets.all(12),
          duration: Duration(seconds: 3),
        );

        canResend.value = true;
      }
    } catch (e, stackTrace) {
      Get.back(); // Close loading dialog

      print('═══════════════════════════════════════');
      print('❌ RESEND ERROR');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('═══════════════════════════════════════');

      String errorMessage = 'Failed to resend OTP. Please try again.';

      if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(12),
        duration: Duration(seconds: 3),
      );

      canResend.value = true;
    }
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    print('🗑️ VerificationController disposed');
    super.onClose();
  }
}