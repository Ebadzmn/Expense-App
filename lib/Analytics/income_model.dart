class Income {
  final String id;
  final String userId;
  final String source;
  final double amount;
  final DateTime date;
  final String month;

  Income({
    required this.id,
    required this.userId,
    required this.source,
    required this.amount,
    required this.date,
    required this.month,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      source: json['source'] ?? '',
      amount: (json['amount'] is int ? json['amount'].toDouble() : json['amount']) ?? 0.0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      month: json['month'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'source': source,
      'amount': amount,
      'date': date.toIso8601String(),
      'month': month,
    };
  }

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedDate => '${_formatDate(date)}, ${_formatTime(date)}';

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12;
    final hour12 = hour == 0 ? 12 : hour;
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

class IncomeResponse {
  final bool success;
  final List<Income> data;
  final Pagination pagination;

  IncomeResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory IncomeResponse.fromJson(Map<String, dynamic> json) {
    return IncomeResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Income.fromJson(item))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
    );
  }
}