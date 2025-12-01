// lib/services/user_service.dart
import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

class UserService extends GetxService {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _configService = Get.find();

  Future<UserService> init() async {
    print('UserService initialized');
    return this;
  }

  // Send OTP to current email - POST method
  Future<Map<String, dynamic>> sendOtpToCurrentEmail() async {
    try {
      print('📧 Sending OTP to current email...');
      final response = await _apiService.request(
        'POST',
        '${_configService.baseUrl}/user/send-otp',
        body: {
          'purpose': 'email_change',
        },
        requiresAuth: false,
      );
      print('✅ OTP sent successfully');
      return response;
    } catch (e) {
      print('❌ Error sending OTP: $e');
      rethrow;
    }
  }

  // Change email with OTP verification - PATCH method
  Future<Map<String, dynamic>> changeEmailWithOtp({
    required String currentEmail,
    required String newEmail,
    required String otp,
  }) async {
    try {
      print('📧 Changing email with OTP verification...');
      print('🔑 Current Email: $currentEmail');
      print('🔑 New Email: $newEmail');
      print('🔑 OTP: $otp');

      final response = await _apiService.request(
        'PATCH',
        '${_configService.baseUrl}/user/change-email',
        body: {
          'currentEmail': currentEmail,
          'newEmail': newEmail,
          'otp': otp,
        },
        requiresAuth: true,
      );
      print('✅ Email changed successfully');
      return response;
    } catch (e) {
      print('❌ Error changing email: $e');
      rethrow;
    }
  }

  // Resend OTP - POST method
  Future<Map<String, dynamic>> resendOtp() async {
    try {
      print('🔄 Resending OTP...');
      final response = await _apiService.request(
        'POST',
        '${_configService.baseUrl}/user/send-otp',
        body: {
          'purpose': 'email_change',
          'resend': true,
        },
        requiresAuth: false,
      );
      print('✅ OTP resent successfully');
      return response;
    } catch (e) {
      print('❌ Error resending OTP: $e');
      rethrow;
    }
  }
}