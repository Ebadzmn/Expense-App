import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/routes/app_routes.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:intl/intl.dart';
import '../services/api_base_service.dart';
import '../services/config_service.dart';
import '../routes/app_routes.dart';
import 'package:your_expense/Analytics/ExpenseService.dart';
import 'package:your_expense/Analytics/income_service.dart';

class AnalyticsController extends GetxController {
  var selectedChartType = 0.obs; // 0=Pie, 1=Bar, 2=Line
  var selectedDataType = 0.obs; // 0=Income, 1=Expense
  var isLoading = false.obs;
  var totalIncome = 0.0.obs;
  var totalExpenses = 0.0.obs; // Now dynamic from API
  var selectedMonth = ''.obs;

  late final ApiBaseService _apiService;
  late final ConfigService _configService;
  late final ExpenseService _expenseService;
  late final IncomeService _incomeService;

  // Dynamic income data from API
  final RxList<ChartData> incomeData = <ChartData>[].obs;

  // Dynamic expense data from API
  final RxList<ChartData> expenseData = <ChartData>[].obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiBaseService>();
    _configService = Get.find<ConfigService>();
    _expenseService = Get.isRegistered<ExpenseService>()
        ? Get.find<ExpenseService>()
        : Get.put(ExpenseService(), permanent: true);
    _incomeService = Get.isRegistered<IncomeService>()
        ? Get.find<IncomeService>()
        : Get.put(IncomeService(), permanent: true);
    final now = DateTime.now();
    selectedMonth.value = DateFormat('yyyy-MM').format(now);
    fetchIncomeSummary();
    fetchExpenseSummary();
  }

  Future<void> fetchIncomeSummary() async {
    try {
      isLoading.value = true;
      // Prefer lowercase 'month' to match backend, fallback to 'Month'
      final okLower = await _fetchIncomeSummaryWithParamKey('month');
      if (!okLower) {
        await _fetchIncomeSummaryWithParamKey('Month');
      }
      // Fallback only if server breakdown looks empty or total is zero
      if (incomeData.isEmpty || totalIncome.value == 0.0) {
        await _buildIncomeBreakdownFromRaw();
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching income summary: $e');
      print('📝 Stack trace: $stackTrace');
      Get.snackbar(
        'Error'.tr,
        'Failed to load income data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      print('✅ Finished loading income data');
    }
  }

  Future<void> fetchExpenseSummary() async {
    try {
      isLoading.value = true;
      // Prefer lowercase 'month' to match backend, fallback to 'Month'
      final okLower = await _fetchExpenseSummaryWithParamKey('month');
      if (!okLower) {
        await _fetchExpenseSummaryWithParamKey('Month');
      }
      // If server breakdown is empty or total is zero, build locally
      if (expenseData.isEmpty || totalExpenses.value == 0.0) {
        await _buildExpenseBreakdownFromRaw();
      } else {
        // Extra guard: if breakdown has only one label, prefer local breakdown
        final uniqueLabels = expenseData.map((e) => e.label).toSet();
        if (uniqueLabels.length <= 1) {
          await _buildExpenseBreakdownFromRaw();
        } else {
          // Ensure total matches raw if server total is stale
          try {
            final items = await _expenseService.getExpenses();
            final month = selectedMonth.value;
            double rawTotal = 0.0;
            for (final e in items) {
              final ym =
                  '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}';
              if (ym == month) rawTotal += e.amount;
            }
            if (rawTotal > totalExpenses.value) {
              totalExpenses.value = rawTotal;
            }
          } catch (e) {
            // ignore raw total fallback errors
            print('⚠️ Raw total fallback failed: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching expense summary: $e');
      print('📝 Stack trace: $stackTrace');
      Get.snackbar(
        'Error'.tr,
        'Failed to load expense data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      print('✅ Finished loading expense data');
    }
  }

  Future<bool> _fetchIncomeSummaryWithParamKey(String key) async {
    try {
      print(
        '🔄 Fetching income summary for month: ${selectedMonth.value} with key "$key"',
      );
      final response = await _apiService.request(
        'GET',
        '${_configService.baseUrl}/income/summary',
        queryParams: {key: selectedMonth.value},
      );
      print('📊 Raw Income API Response: $response');
      if (response is Map && response['success'] == true) {
        final data = response['data'];
        totalIncome.value = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
        final breakdown =
            (data['breakdown'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            [];
        incomeData.clear();
        final incomeColors = [
          const Color(0xFF00BCD4),
          const Color(0xFFFFC107),
          const Color(0xFF4CAF50),
          const Color(0xFF2196F3),
          const Color(0xFF9C27B0),
          const Color(0xFFFF5252),
        ];
        for (int i = 0; i < breakdown.length; i++) {
          final source = breakdown[i];
          final color = incomeColors[i % incomeColors.length];
          final sourceName =
              (source['source'] ??
                      source['category'] ??
                      source['categoryName'] ??
                      '')
                  .toString();
          final amount = (source['amount'] as num?)?.toDouble() ?? 0.0;
          incomeData.add(
            ChartData(label: sourceName, value: amount, color: color),
          );
        }
        update();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Income summary with key "$key" failed: $e');
      return false;
    }
  }

  Future<bool> _fetchExpenseSummaryWithParamKey(String key) async {
    try {
      print(
        '🔄 Fetching expense summary for month: ${selectedMonth.value} with key "$key"',
      );
      final response = await _apiService.request(
        'GET',
        '${_configService.baseUrl}/expense/summary',
        queryParams: {key: selectedMonth.value},
      );
      print('📊 Raw Expense API Response: $response');
      if (response is Map && response['success'] == true) {
        final data = response['data'];
        totalExpenses.value = (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
        final breakdown =
            (data['breakdown'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            [];
        expenseData.clear();
        final expenseColors = [
          const Color(0xFFFF5252),
          const Color(0xFF4CAF50),
          const Color(0xFF2196F3),
          const Color(0xFFFFC107),
          const Color(0xFF9C27B0),
          const Color(0xFF00BCD4),
        ];
        for (int i = 0; i < breakdown.length; i++) {
          final category = breakdown[i];
          final color = expenseColors[i % expenseColors.length];
          final categoryName =
              (category['categoryName'] ??
                      category['category'] ??
                      category['source'] ??
                      '')
                  .toString();
          final amount = (category['amount'] as num?)?.toDouble() ?? 0.0;
          expenseData.add(
            ChartData(label: categoryName, value: amount, color: color),
          );
        }
        update();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Expense summary with key "$key" failed: $e');
      return false;
    }
  }

  Future<void> _buildExpenseBreakdownFromRaw() async {
    try {
      print(
        '🛠️ Building expense breakdown locally for ${selectedMonth.value}',
      );
      final items = await _expenseService.getExpenses();
      final month = selectedMonth.value;
      final filtered = items.where((e) {
        final ym =
            '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}';
        return ym == month;
      }).toList();
      final Map<String, double> grouped = {};
      for (final e in filtered) {
        final key = e.category.isNotEmpty ? e.category : 'Other';
        grouped[key] = (grouped[key] ?? 0.0) + e.amount;
      }
      expenseData.clear();
      final expenseColors = [
        const Color(0xFFFF5252),
        const Color(0xFF4CAF50),
        const Color(0xFF2196F3),
        const Color(0xFFFFC107),
        const Color(0xFF9C27B0),
        const Color(0xFF00BCD4),
      ];
      int i = 0;
      double total = 0.0;
      grouped.forEach((label, value) {
        final color = expenseColors[i % expenseColors.length];
        expenseData.add(ChartData(label: label, value: value, color: color));
        total += value;
        i++;
      });
      totalExpenses.value = total;
      update();
    } catch (e) {
      print('⚠️ Local expense breakdown failed: $e');
    }
  }

  Future<void> _buildIncomeBreakdownFromRaw() async {
    try {
      print('🛠️ Building income breakdown locally for ${selectedMonth.value}');
      // Fetch a large page to avoid truncation
      final resp = await _incomeService.getIncomes(
        page: 1,
        limit: 1000,
        month: selectedMonth.value,
      );
      final items = resp.data;
      final Map<String, double> grouped = {};
      for (final inc in items) {
        final key = inc.source.isNotEmpty ? inc.source : 'Income';
        grouped[key] = (grouped[key] ?? 0.0) + inc.amount;
      }
      incomeData.clear();
      final incomeColors = [
        const Color(0xFF00BCD4),
        const Color(0xFFFFC107),
        const Color(0xFF4CAF50),
        const Color(0xFF2196F3),
        const Color(0xFF9C27B0),
        const Color(0xFFFF5252),
      ];
      int i = 0;
      double total = 0.0;
      grouped.forEach((label, value) {
        final color = incomeColors[i % incomeColors.length];
        incomeData.add(ChartData(label: label, value: value, color: color));
        total += value;
        i++;
      });
      totalIncome.value = total;
      update();
    } catch (e) {
      print('⚠️ Local income breakdown failed: $e');
    }
  }

  Future<void> fetchAllData() async {
    try {
      isLoading.value = true;
      await Future.wait([fetchIncomeSummary(), fetchExpenseSummary()]);
    } catch (e) {
      print('❌ Error fetching all data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateMonth(String newMonth) {
    selectedMonth.value = newMonth;
    fetchAllData();
  }

  // Data type methods
  List<String> get dataTypes => ['Income', 'Expense', 'Both'];

  String get currentDataTypeName => dataTypes[selectedDataType.value];

  void selectDataType(int index) {
    selectedDataType.value = index;
    update(); // Force UI update
  }

  // Get current data based on selection
  List<ChartData> getCurrentData() {
    if (selectedDataType.value == 2) {
      return [...incomeData, ...expenseData];
    }
    return selectedDataType.value == 0 ? incomeData : expenseData;
  }

  double getCurrentTotal() {
    if (selectedDataType.value == 2) {
      return totalIncome.value + totalExpenses.value;
    }
    return selectedDataType.value == 0
        ? totalIncome.value
        : totalExpenses.value;
  }

  String getCurrentDataTypeTitle() {
    if (selectedDataType.value == 2) {
      return 'Income & Expenses'.tr;
    }
    return selectedDataType.value == 0 ? 'income'.tr : 'expenses'.tr;
  }

  // Chart data methods based on current selection
  List<ChartData> getCurrentPieChartData() {
    return getCurrentData();
  }

  List<ChartData> getCurrentBarChartData() {
    return getCurrentData();
  }

  List<ChartData> getCurrentLineChartData() {
    final data = getCurrentData();
    if (data.isNotEmpty) {
      return data;
    }

    // Fallback sample data
    return selectedDataType.value == 0
        ? [
            ChartData(label: 'Salary', value: 26000, color: Colors.blue),
            ChartData(label: 'Rent', value: 8470, color: Colors.green),
          ]
        : [
            ChartData(
              label: 'Shopping',
              value: 700,
              color: const Color(0xFFFF5252),
            ),
            ChartData(
              label: 'Medicine',
              value: 700,
              color: const Color(0xFF4CAF50),
            ),
          ];
  }

  // Legacy methods for backward compatibility
  List<ChartData> getIncomePieChartData() {
    return incomeData;
  }

  List<ChartData> getIncomeBarChartData() {
    return incomeData;
  }

  List<ChartData> getIncomeLineChartData() {
    if (incomeData.isNotEmpty) {
      return incomeData;
    }

    // Fallback sample data
    return [
      ChartData(label: 'Salary', value: 26000, color: Colors.blue),
      ChartData(label: 'Rent', value: 8470, color: Colors.green),
    ];
  }

  List<ChartData> getExpensePieChartData() {
    return expenseData;
  }

  List<ChartData> getExpenseBarChartData() {
    return expenseData;
  }

  List<ChartData> getExpenseLineChartData() {
    return expenseData;
  }

  String getCurrentMonthAndYear() {
    try {
      final date = DateFormat('yyyy-MM').parse(selectedMonth.value);
      return DateFormat('MMMM, yyyy').format(date);
    } catch (e) {
      final now = DateTime.now();
      return DateFormat('MMMM, yyyy').format(now);
    }
  }

  String getFormattedTotalIncome() {
    return '\$${totalIncome.value.toStringAsFixed(0)}';
  }

  String getFormattedTotalExpenses() {
    return '\$${totalExpenses.value.toStringAsFixed(0)}';
  }

  void selectChartType(int index) {
    selectedChartType.value = index;
  }

  void onExpensesClick() {
    Get.toNamed(
      AppRoutes.expensesScreen,
      arguments: {'month': selectedMonth.value},
    );
  }

  void onIncomeClick() {
    Get.toNamed(AppRoutes.incomeScreen);
  }

  void onExportReportClick() {
    final sub = Get.find<SubscriptionService>();
    if (!sub.isActivePro) {
      Get.snackbar(
        'Pro Required',
        'Export report is only available for Pro users.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.toNamed(AppRoutes.premiumPlans);
      return;
    }
    Get.toNamed(AppRoutes.uploadToDrive);
  }

  List<String> get chartTypes => ['Pie Chart', 'Bar Chart', 'Line chart'];

  String get currentChartTypeName => chartTypes[selectedChartType.value];
}

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData({required this.label, required this.value, required this.color});
}
