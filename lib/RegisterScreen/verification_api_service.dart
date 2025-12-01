import 'package:get/get.dart';
import 'package:your_expense/RegisterScreen/verification_model.dart';
import '../services/api_base_service.dart';
import '../services/config_service.dart';

class VerificationApiService extends ApiBaseService {
  final ConfigService _config = Get.find();

  // Verify Email
  Future<VerifyEmailResponse> verifyEmail(String email, int oneTimeCode) async {
    final requestBody = VerifyEmailRequest(
      email: email,
      oneTimeCode: oneTimeCode,
    ).toJson();

    print('Sending verify email request: $requestBody');

    final response = await request(
      'POST',
      _config.verifyEmailEndpoint,
      body: requestBody,
      requiresAuth: false, // Verification should not require auth
    );

    return VerifyEmailResponse.fromJson(response);
  }

  // Resend OTP
  Future<ResendOtpResponse> resendOtp(String email) async {
    final requestBody = ResendOtpRequest(email: email).toJson();

    print('Sending resend OTP request: $requestBody');

    final response = await request(
      'POST',
      _config.resendOtpEndpoint,
      body: requestBody,
      requiresAuth: false, // Resend OTP should not require auth
    );

    return ResendOtpResponse.fromJson(response);
  }

  Future<VerificationApiService> init() async {
    print('VerificationApiService initialized');
    return this;
  }
}