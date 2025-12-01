// models/budget_distribution_model.dart
class BudgetDistribution {
  final String month;
  final double totalPercentageUsed;
  final List<BudgetCategory> categories;

  BudgetDistribution({
    required this.month,
    required this.totalPercentageUsed,
    required this.categories,
  });

  factory BudgetDistribution.fromJson(Map<String, dynamic> json) {
    return BudgetDistribution(
      month: json['month'] ?? '',
      totalPercentageUsed: double.tryParse(json['totalPercentageUsed'] ?? '0') ?? 0.0,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((category) => BudgetCategory.fromJson(category))
          .toList() ?? [],
    );
  }
}

class BudgetCategory {
  final String categoryId;
  final double budgetAmount;
  final double percentageUsed;

  BudgetCategory({
    required this.categoryId,
    required this.budgetAmount,
    required this.percentageUsed,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      categoryId: json['categoryId'] ?? '',
      budgetAmount: double.tryParse(json['budgetAmount'] ?? '0') ?? 0.0,
      percentageUsed: double.tryParse(json['percentageUsed'] ?? '0') ?? 0.0,
    );
  }
}