class ExpenseItem {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String note;
  final DateTime createdAt;

  ExpenseItem({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.note,
    required this.createdAt,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    // Handle different amount formats
    double parsedAmount;
    if (json['amount'] is int) {
      parsedAmount = (json['amount'] as int).toDouble();
    } else if (json['amount'] is double) {
      parsedAmount = json['amount'] as double;
    } else if (json['amount'] is String) {
      parsedAmount = double.tryParse(json['amount'] as String) ?? 0.0;
    } else {
      parsedAmount = 0.0;
    }

    // Parse createdAt date
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['createdAt']?.toString() ?? '');
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return ExpenseItem(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      amount: parsedAmount,
      // Prefer backend 'source' first, then 'categoryName', then 'category'
      category: (json['source'] ?? json['categoryName'] ?? json['category'] ?? '').toString(),
      note: json['note']?.toString() ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year.toString().substring(2)}, ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'ExpenseItem{id: $id, amount: $amount, category: $category, note: $note}';
  }
}