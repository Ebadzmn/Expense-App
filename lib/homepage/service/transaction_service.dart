import 'package:get/get.dart';

import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

import '../model/transaction.dart';

class TransactionService extends GetxService {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _configService = Get.find();

  Future<TransactionService> init() async {
    print('TransactionService initialized');
    return this;
  }

  Future<List<Transaction>> fetchRecentTransactions() async {
    try {
      final response = await _apiService.request(
        'GET',
        _configService.recentTransactionsEndpoint,
        requiresAuth: true,
      );

      List<dynamic> rawList = [];

      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        // Typical shape { success: true, data: { transactions: [...] } }
        final data = response['data'];
        if (data is Map<String, dynamic> && data['transactions'] is List) {
          rawList = data['transactions'] as List<dynamic>;
        } else if (response['transactions'] is List) {
          rawList = response['transactions'] as List<dynamic>;
        } else if (data is List) {
          rawList = data;
        } else if (response['items'] is List) {
          rawList = response['items'] as List<dynamic>;
        } else {
          throw Exception('No transactions list found in response');
        }
      } else {
        throw Exception('Unexpected response type: ${response.runtimeType}');
      }

      final transactions = rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => Transaction.fromJson(json))
          .toList();

      return transactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      Get.snackbar('Error', 'Failed to fetch transactions: $e');
      rethrow;
    }
  }
}