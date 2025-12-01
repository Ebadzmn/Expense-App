class VerifyEmailRequest {
  final String email;
  final int oneTimeCode;

  VerifyEmailRequest({required this.email, required this.oneTimeCode});

  Map<String, dynamic> toJson() => {
    'email': email,
    'oneTimeCode': oneTimeCode,
  };
}

class VerifyEmailResponse {
  final bool success;
  final String message;
  final List<ErrorMessage>? errorMessages;
  final String? stack;

  VerifyEmailResponse({
    required this.success,
    required this.message,
    this.errorMessages,
    this.stack,
  });

  factory VerifyEmailResponse.fromJson(Map<String, dynamic> json) {
    print('Raw Verify Email API Response: $json');

    return VerifyEmailResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? (json['success'] == true ? 'Success' : 'Unknown error'),
      errorMessages: json['errorMessages'] != null
          ? (json['errorMessages'] as List)
              .map((e) => ErrorMessage.fromJson(e))
              .toList()
          : null,
      stack: json['stack'],
    );
  }
}

class ResendOtpRequest {
  final String email;

  ResendOtpRequest({required this.email});

  Map<String, dynamic> toJson() => {
    'email': email,
  };
}

class ResendOtpResponse {
  final bool success;
  final String message;
  final List<ErrorMessage>? errorMessages; // Added errorMessages for consistency
  final String? stack; // Added stack for consistency

  ResendOtpResponse({
    required this.success,
    required this.message,
    this.errorMessages,
    this.stack,
  });

  factory ResendOtpResponse.fromJson(Map<String, dynamic> json) {
    print('Raw Resend OTP API Response: $json');

    return ResendOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      errorMessages: json['errorMessages'] != null
          ? (json['errorMessages'] as List)
              .map((e) => ErrorMessage.fromJson(e))
              .toList()
          : null,
      stack: json['stack'],
    );
  }
}

class ErrorMessage {
  final String message;
  final String? field;

  ErrorMessage({required this.message, this.field});

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      message: json['message'] ?? 'Unknown error',
      field: json['field'],
    );
  }
}