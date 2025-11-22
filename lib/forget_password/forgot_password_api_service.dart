import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

class ForgotPasswordApiService extends ApiBaseService {
  final ConfigService _config = Get.find();

  Future<ForgotPasswordApiService> init() async {
    return this;
  }

  /// Step 1: Send email to request password reset.
  /// Uses the explicit `forget-password` endpoint.
  Future<Map<String, dynamic>> requestForgetPassword(String email) async {
    final body = { 'email': email };
    final resp = await request(
      'POST',
      _config.forgetPasswordEndpoint,
      body: body,
      requiresAuth: false,
    );
    return resp as Map<String, dynamic>;
  }

  /// Step 2: Verify OTP to get a reset token.
  /// Backend is shared with registration: `/auth/verify-email`.
  Future<Map<String, dynamic>> verifyEmailOtp({required String email, required int oneTimeCode}) async {
    final body = {
      'email': email,
      'oneTimeCode': oneTimeCode,
    };
    final resp = await request(
      'POST',
      _config.verifyEmailEndpoint,
      body: body,
      requiresAuth: false,
    );
    return resp as Map<String, dynamic>;
  }

  /// Resend OTP for the given email (no auth required).
  Future<Map<String, dynamic>> resendOtp(String email) async {
    final body = {
      'email': email,
    };
    final resp = await request(
      'POST',
      _config.resendOtpEndpoint,
      body: body,
      requiresAuth: false,
    );
    return resp as Map<String, dynamic>;
  }

  /// Step 3: Reset password using the received token.
  /// Token is provided via Authorization header (raw token, no Bearer) and also in body.
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final body = {
      'token': token,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
    final resp = await request(
      'POST',
      _config.resetPasswordEndpoint,
      body: body,
      headers: {
        'Authorization': token,
      },
      requiresAuth: false,
    );
    return resp as Map<String, dynamic>;
  }
}