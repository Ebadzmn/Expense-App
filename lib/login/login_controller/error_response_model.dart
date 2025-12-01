// models/error_response_model.dart
class ErrorResponseModel {
  final bool success;
  final String message;
  final List<Map<String, dynamic>> errorMessages;
  final String? stack;

  ErrorResponseModel({
    required this.success,
    required this.message,
    required this.errorMessages,
    this.stack,
  });

  factory ErrorResponseModel.fromJson(Map<String, dynamic> json) {
    return ErrorResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? 'An error occurred',
      errorMessages: json['errorMessages'] != null
          ? List<Map<String, dynamic>>.from(json['errorMessages'])
          : [],
      stack: json['stack'],
    );
  }

  String getFormattedErrorMessage() {
    if (errorMessages.isNotEmpty) {
      return errorMessages
          .map((error) => error['message']?.toString() ?? '')
          .where((message) => message.isNotEmpty)
          .join(', ');
    }
    return message;
  }
}