import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'income_model.dart';
import 'package:intl/intl.dart';

class IncomeService extends GetxService {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _config = Get.find();

  Future<IncomeService> init() async {
    print('IncomeService initialized');
    return this;
  }

  Future<IncomeResponse> getIncomes({
    int page = 1,
    int limit = 10,
    String? month,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (month != null) 'month': month,
      };

      final response = await _apiService.request(
        'GET',
        _config.incomeEndpoint,
        queryParams: queryParams,
        requiresAuth: true,
      );

      return IncomeResponse.fromJson(response);
    } catch (e) {
      print('Error fetching incomes: $e');
      rethrow;
    }
  }

  Future<Income> createIncome({
    required String source,
    required double amount,
    DateTime? date,
    String? month,
  }) async {
    try {
      final effectiveDate = date ?? DateTime.now();
      final monthStr = DateFormat('yyyy-MM').format(effectiveDate);
      final isoDate = effectiveDate.toIso8601String();
      final body = {
        'source': source,
        'amount': amount,
        // Always include date fields and month derived from date
        'date': isoDate,
        'createdAt': isoDate,
        'month': (month != null && month.isNotEmpty) ? month : monthStr,
      };

      final response = await _apiService.request(
        'POST',
        _config.incomeEndpoint,
        body: body,
        requiresAuth: true,
      );

      return Income.fromJson(response['data'] ?? {});
    } catch (e) {
      print('Error creating income: $e');
      rethrow;
    }
  }

  Future<Income> updateIncome({
    required String id,
    String? source,
    double? amount,
    DateTime? date,
  }) async {
    try {
      final body = {
        if (source != null) 'source': source,
        if (amount != null) 'amount': amount,
        if (date != null) 'date': date.toIso8601String(),
      };

      final response = await _apiService.request(
        'PUT',
        '${_config.incomeEndpoint}/$id',
        body: body,
        requiresAuth: true,
      );

      return Income.fromJson(response['data'] ?? {});
    } catch (e) {
      print('Error updating income: $e');
      rethrow;
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await _apiService.request(
        'DELETE',
        '${_config.incomeEndpoint}/$id',
        requiresAuth: true,
      );
    } catch (e) {
      print('Error deleting income: $e');
      rethrow;
    }
  }
}