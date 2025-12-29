class Budget {
  final String month;
  final double totalIncome;
  final double totalBudget;
  final double totalCategoryAmount;
  final double effectiveTotalBudget;
  final double totalExpense;
  final double totalRemaining;
  final double totalPercentageUsed;
  final double totalPercentageLeft;
  final List<BudgetCategory> categories;

  Budget({
    required this.month,
    required this.totalIncome,
    required this.totalBudget,
    required this.totalCategoryAmount,
    required this.effectiveTotalBudget,
    required this.totalExpense,
    required this.totalRemaining,
    required this.totalPercentageUsed,
    required this.totalPercentageLeft,
    required this.categories,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    var categoriesList = <BudgetCategory>[];
    if (json['categories'] != null && json['categories'] is List) {
      for (var v in json['categories']) {
        try {
          if (v is Map) {
            categoriesList.add(BudgetCategory.fromJson(Map<String, dynamic>.from(v)));
          }
        } catch (e) {
          print('Error parsing budget category: $e');
        }
      }
    }

    return Budget(
      month: json['month'] ?? '',
      totalIncome: double.tryParse(json['totalIncome']?.toString() ?? '0') ?? 0.0,
      totalBudget: double.tryParse(json['totalBudget']?.toString() ?? '0') ?? 0.0,
      totalCategoryAmount: double.tryParse(json['totalCategoryAmount']?.toString() ?? '0') ?? 0.0,
      effectiveTotalBudget: double.tryParse(json['effectiveTotalBudget']?.toString() ?? '0') ?? 0.0,
      totalExpense: double.tryParse(json['totalExpense']?.toString() ?? '0') ?? 0.0,
      totalRemaining: double.tryParse(json['totalRemaining']?.toString() ?? '0') ?? 0.0,
      totalPercentageUsed: double.tryParse(json['totalPercentageUsed']?.toString() ?? '0') ?? 0.0,
      totalPercentageLeft: double.tryParse(json['totalPercentageLeft']?.toString() ?? '0') ?? 0.0,
      categories: categoriesList,
    );
  }
}

class BudgetCategory {
  final String categoryId;
  final String? id;
  final double budgetAmount;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final String status;

  BudgetCategory({
    required this.categoryId,
    required this.id,
    required this.budgetAmount,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.status,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    String? pickId() {
      const keys = ['_id', 'id', 'budgetCategoryId', 'categoryBudgetId'];
      for (final k in keys) {
        final v = json[k]?.toString();
        if (v != null && v.trim().isNotEmpty) {
          return v.trim();
        }
      }
      final categoryId = json['categoryId']?.toString();
      if (categoryId != null &&
          RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(categoryId.trim())) {
        return categoryId.trim();
      }
      return null;
    }

    final parsedId = pickId();
    final rawAmount = json['budgetAmount'] ?? json['amount'];
    return BudgetCategory(
      categoryId: json['categoryId'] ?? '',
      id: parsedId,
      budgetAmount: double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0,
      spent: double.tryParse(json['spent']?.toString() ?? '0') ?? 0.0,
      remaining: double.tryParse(json['remaining']?.toString() ?? '0') ?? 0.0,
      percentageUsed: double.tryParse(json['percentageUsed']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'good',
    );
  }
}
