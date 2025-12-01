class MonthlyBudget {
  final String month;
  final double totalBudget;
  final double totalCategoryAmount;
  final List<dynamic> categories;

  MonthlyBudget({
    required this.month,
    required this.totalBudget,
    required this.totalCategoryAmount,
    required this.categories,
  });

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) {
    return MonthlyBudget(
      month: json['month'] ?? '',
      totalBudget: (json['totalBudget'] ?? 0).toDouble(),
      totalCategoryAmount: (json['totalCategoryAmount'] ?? 0).toDouble(),
      categories: json['categories'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'totalBudget': totalBudget,
      'totalCategoryAmount': totalCategoryAmount,
      'categories': categories,
    };
  }
}

class BudgetRequest {
  final String month;
  final double totalBudget;
  final List<dynamic> categories;

  BudgetRequest({
    required this.month,
    required this.totalBudget,
    this.categories = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'totalBudget': totalBudget,
      'categories': categories,
    };
  }
}

class BudgetResponse {
  final bool success;
  final String message;
  final MonthlyBudget data;

  BudgetResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BudgetResponse.fromJson(Map<String, dynamic> json) {
    return BudgetResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: MonthlyBudget.fromJson(json['data'] ?? {}),
    );
  }
}