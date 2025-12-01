class Transaction {
  final String id;
  final String title;
  final String type;
  final String amount;
  final String time;
  bool get isIncome => type == 'income';

  Transaction({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.time,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    String rawTitle = (json['title'] ?? json['name'] ?? json['categoryName'] ?? json['note'] ?? json['category'] ?? json['source'] ?? json['description'] ?? 'Unknown').toString();
    final bool isIdLike = RegExp(r'^[a-f0-9]{24}$').hasMatch(rawTitle);
    if (isIdLike) {
      rawTitle = (json['name'] ?? json['categoryName'] ?? json['source'] ?? json['note'] ?? 'Transaction').toString();
    }

    final dynamic amt = json['amount'];
    final String amountStr = amt is num ? amt.toString() : (amt?.toString() ?? '0');
    final String timeStr = (json['time'] ?? json['createdAt'] ?? json['date'] ?? '').toString();

    return Transaction(
      id: json['_id']?.toString() ?? '',
      title: rawTitle,
      type: (json['type'] ?? '').toString(),
      amount: amountStr,
      time: timeStr,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': time,
      'amount': amount,
      'isIncome': isIncome,
    };
  }

  // Helper method to get numeric amount (remove +, - signs and parse)
  double get numericAmount {
    final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanAmount) ?? 0.0;
  }
}