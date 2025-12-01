import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:your_expense/routes/app_routes.dart';
import '../forgot_password_api_service.dart';
import '../../Settings/appearance/ThemeController.dart';
import '../../Settings/language/language_controller.dart';
import 'package:your_expense/services/token_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final ThemeController themeController = Get.find<ThemeController>();
  final LanguageController languageController = Get.find<LanguageController>();
  final Color primaryColor = Color(0xFF4A90E2); // Using #4A90E2 as primary color
  late final String? _email;
  bool _canResend = false; // disable initially, start countdown
  int _resendCountdown = 120; // 2 minutes
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _email = (Get.arguments is Map) ? (Get.arguments as Map)['email']?.toString() : null;
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onSubmit() {
    String otpCode = _controllers.map((c) => c.text).join();
    if (otpCode.length == 4) {
      _verifyOtpAndProceed(otpCode);
    } else {
      Get.snackbar(
        'Error'.tr,
        'Please enter a valid 4-digit OTP'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: themeController.isDarkModeActive
            ? Colors.grey[800]
            : Colors.white,
        colorText: themeController.isDarkModeActive
            ? Colors.white
            : Colors.black,
      );
    }
  }

  void _startCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 120; // 2 minutes
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() {
          _canResend = true;
          _resendCountdown = 0;
        });
      } else {
        setState(() {
          _resendCountdown -= 1;
        });
      }
    });
  }

  Future<void> _resendOtp() async {
    final email = _email ?? (Get.arguments is Map ? (Get.arguments as Map)['email']?.toString() : null);
    if (email == null || email.isEmpty) {
      Get.snackbar('Error'.tr, 'Email missing. Please restart flow.'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!_canResend) return;

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final service = Get.isRegistered<ForgotPasswordApiService>()
          ? Get.find<ForgotPasswordApiService>()
          : Get.put(ForgotPasswordApiService());
      await service.init();
      await service.resendOtp(email);

      Get.back();
      Get.snackbar(
        'codeResent'.tr,
        'newCodeSent'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: themeController.isDarkModeActive
            ? const Color(0xFF2D2D2D)
            : const Color(0xFF2196F3),
        colorText: Colors.white,
      );

      _startCountdown();
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error'.tr,
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _verifyOtpAndProceed(String otp) async {
    final email = _email ?? (Get.arguments is Map ? (Get.arguments as Map)['email']?.toString() : null);
    if (email == null || email.isEmpty) {
      Get.snackbar('Error'.tr, 'Email missing. Please restart flow.'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      final service = Get.isRegistered<ForgotPasswordApiService>()
          ? Get.find<ForgotPasswordApiService>()
          : Get.put(ForgotPasswordApiService());
      await service.init();
      final resp = await service.verifyEmailOtp(email: email, oneTimeCode: int.parse(otp));
      final success = resp['success'] == true;
      final token = resp['data']?.toString();
      final message = resp['message']?.toString() ?? (success ? 'Verified' : 'Verification failed');
      if (success && token != null && token.isNotEmpty) {
        // Persist reset token for later use
        try {
          final tokenService = Get.isRegistered<TokenService>() ? Get.find<TokenService>() : Get.put(TokenService());
          await tokenService.init();
          await tokenService.saveResetToken(token);
        } catch (e) {
          print('⚠️ Failed to persist reset token: $e');
        }
        Get.snackbar('Success'.tr, message, snackPosition: SnackPosition.BOTTOM);
        Get.offNamed(AppRoutes.setNewPassword, arguments: {'token': token});
      } else {
        Get.snackbar('Error'.tr, message, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error'.tr, e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkModeActive;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Lock Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'verification_code'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'sent_code'.tr,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'enter_six_digit'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return Container(
                    width: 48,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _focusNodes[index].hasFocus
                            ? primaryColor
                            : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        filled: true,
                        fillColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          if (index < _focusNodes.length - 1) {
                            FocusScope.of(context)
                                .requestFocus(_focusNodes[index + 1]);
                          } else {
                            _focusNodes[index].unfocus();
                          }
                        } else {
                          if (index > 0) {
                            FocusScope.of(context)
                                .requestFocus(_focusNodes[index - 1]);
                          }
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  );
                }),
              ),

             


              const SizedBox(height: 16),

              // Resend Code
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'dont_get_code'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _canResend
                        ? GestureDetector(
                            onTap: _resendOtp,
                            child: Text(
                              'resend'.tr,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        : Text(
                            'resend_in'.trParams({'seconds': _resendCountdown.toString()}),
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'submit'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Back to Sign In Button
              Center(
                child: TextButton(
                  onPressed: () {
                    Get.offNamed(AppRoutes.register);
                  },
                  child: Text(
                    'back_to_sign_in'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}