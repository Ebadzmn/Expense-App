import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

import '../model/budget.dart';

class BudgetService extends GetxService {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _configService = Get.find();

  Future<BudgetService> init() async {
    return this;
  }

  // New method to fetch monthly budget data with specific month parameter
  Future<Budget> fetchMonthlyBudgetData({String? month}) async {
    try {
      // Use provided month or default to current month
      final monthParam = month ?? DateFormat('yyyy-MM').format(DateTime.now());

      // Prefer path-style endpoint: /budget/{YYYY-MM}
      final response = await _apiService.request(
        'GET',
        _configService.getBudgetEndpoint(monthParam),
        requiresAuth: true,
      );
      print("📊 fetchMonthlyBudgetData response: $response");

      if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          return Budget.fromJson(data);
        }
        // Some APIs may return the budget object directly
        return Budget.fromJson(response);
      }

      throw Exception('Failed to fetch monthly budget data: unexpected response');
    } on HttpException catch (e) {
      if (e.statusCode == 404) {
        // No budget set for this month; return zeroed Budget
        final monthParam = month ?? DateFormat('yyyy-MM').format(DateTime.now());
        return Budget(
          month: monthParam,
          totalIncome: 0.0,
          totalBudget: 0.0,
          totalCategoryAmount: 0.0,
          effectiveTotalBudget: 0.0,
          totalExpense: 0.0,
          totalRemaining: 0.0,
          totalPercentageUsed: 0.0,
          totalPercentageLeft: 0.0,
          categories: [],
        );
      }
      Get.snackbar('Error', 'Failed to fetch monthly budget data: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error fetching monthly budget data: $e');
      Get.snackbar('Error', 'Failed to fetch monthly budget data. Please try again.');
      rethrow;
    }
  }

  // Fetch only the simple monthly budget amount using `simple-monthly-budget?Month=`
  Future<double> fetchSimpleMonthlyBudgetAmount({String? month}) async {
    try {
      final monthParam = month ?? DateFormat('yyyy-MM').format(DateTime.now());
      final url = _configService.getMonthlyBudgetSimpleEndpoint(monthParam);

      final response = await _apiService.request(
        'GET',
        url,
        requiresAuth: true,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        final data = response['data'];
        dynamic amount = data?['amount'];
        if (amount is String) {
          return double.tryParse(amount) ?? 0.0;
        } else if (amount is num) {
          return (amount as num).toDouble();
        } else {
          return 0.0;
        }
      }
      // If API returns success false or unexpected shape
      return 0.0;
    } on HttpException catch (e) {
      if (e.statusCode == 404) {
        // No budget set for this month; return zero
        return 0.0;
      }
      Get.snackbar('Error', 'Failed to fetch monthly budget amount: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error fetching simple monthly budget amount: $e');
      Get.snackbar('Error', 'Failed to fetch monthly budget amount. Please try again.');
      rethrow;
    }
  }
}
