class TermsAndConditions {
  final String id;
  final String content;
  final String version;
  final DateTime effectiveDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TermsAndConditions({
    required this.id,
    required this.content,
    required this.version,
    required this.effectiveDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TermsAndConditions.fromJson(Map<String, dynamic> json) {
    return TermsAndConditions(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      version: json['version'] ?? '',
      effectiveDate: DateTime.parse(json['effectiveDate'] ?? DateTime.now().toString()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }
}

class TermsAndConditionsResponse {
  final bool success;
  final String message;
  final List<TermsAndConditions> data;

  TermsAndConditionsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TermsAndConditionsResponse.fromJson(Map<String, dynamic> json) {
    return TermsAndConditionsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List? ?? [])
          .map((item) => TermsAndConditions.fromJson(item))
          .toList(),
    );
  }
}