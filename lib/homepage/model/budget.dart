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
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
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
    );
  }
}