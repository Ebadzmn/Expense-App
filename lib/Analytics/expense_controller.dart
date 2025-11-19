import 'package:get/get.dart';

import '../home/home_controller.dart';
import 'ExpenseService.dart';
import 'expense_model.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/services/token_service.dart';

import 'package:your_expense/Analytics/analytics_controller.dart';

class ExpenseController extends GetxController {
  final ExpenseService _expenseService = Get.find();
  final ConfigService _configService = Get.find();

  final RxList<ExpenseItem> allExpenses = <ExpenseItem>[].obs;
  final RxList<ExpenseItem> expenses = <ExpenseItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedMonth = ''.obs;
  final RxString lastKnownMonth = ''.obs; // Track month changes

  @override
  void onInit() {
    super.onInit();
    // Initialize selected month from arguments or current month
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('month') && (args['month'] as String).isNotEmpty) {
      selectedMonth.value = args['month'] as String;
    } else if (Get.isRegistered<AnalyticsController>()) {
      selectedMonth.value = Get.find<AnalyticsController>().selectedMonth.value;
    } else {
      selectedMonth.value = _configService.getCurrentMonth();
    }
    
    // Set initial last known month
    lastKnownMonth.value = selectedMonth.value;
    
    // Monitor month changes automatically
    _startMonthChangeMonitoring();

    // Subscribe to global Analytics month selection and propagate
    if (Get.isRegistered<AnalyticsController>()) {
      final analytics = Get.find<AnalyticsController>();
      ever<String>(analytics.selectedMonth, (m) {
        updateMonth(m);
      });
    }

    // Only load expenses when user is authenticated
    if (Get.isRegistered<TokenService>()) {
      final tokenService = Get.find<TokenService>();
      if (tokenService.isTokenValid()) {
        loadExpenses();
      } else {
        print('ExpenseController: Skipping initial load; user not authenticated.');
      }
    } else {
      print('ExpenseController: TokenService not registered; skipping initial load.');
    }
  }

  /// Monitors for month changes and automatically resets to current month
  void _startMonthChangeMonitoring() {
    // Check every minute for month changes
    ever(selectedMonth, (String month) {
      final currentMonth = _configService.getCurrentMonth();
      if (lastKnownMonth.value != currentMonth) {
        // Month has changed, automatically switch to current month
        print('Month changed from ${lastKnownMonth.value} to $currentMonth');
        lastKnownMonth.value = currentMonth;
        if (selectedMonth.value == lastKnownMonth.value) {
          // Only auto-switch if user was viewing the previous current month
          updateMonth(currentMonth);
        }
      }
    });
    
    // Also check periodically (every 30 seconds)
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      final currentMonth = _configService.getCurrentMonth();
      if (lastKnownMonth.value != currentMonth) {
        lastKnownMonth.value = currentMonth;
        // Auto-switch only if user is viewing what was the current month
        if (selectedMonth.value == _configService.getCurrentMonth()) {
          updateMonth(currentMonth);
        }
      }
    });
  }

  Future<void> loadExpenses() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final List<ExpenseItem> fetchedExpenses = await _expenseService.getExpenses();
      allExpenses.assignAll(fetchedExpenses);

      applyMonthFilter();
    } catch (e) {
      errorMessage.value = 'Failed to load expenses: ${e.toString()}';
      print('Error loading expenses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateMonth(String month) {
    selectedMonth.value = month;
    applyMonthFilter();
  }

  void applyMonthFilter() {
    if (selectedMonth.value.isEmpty) {
      expenses.assignAll(allExpenses);
    } else {
      final filtered = allExpenses.where((expense) {
        final ym = '${expense.createdAt.year}-${expense.createdAt.month.toString().padLeft(2, '0')}';
        return ym == selectedMonth.value;
      }).toList();
      expenses.assignAll(filtered);
    }
    // Sort by date (newest first)
    expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get expenses for a specific month without changing the current filter
  List<ExpenseItem> getExpensesForMonth(String month) {
    return allExpenses.where((expense) {
      final ym = '${expense.createdAt.year}-${expense.createdAt.month.toString().padLeft(2, '0')}';
      return ym == month;
    }).toList();
  }

  /// Check if current month has any expenses
  bool get currentMonthHasExpenses {
    final currentMonth = _configService.getCurrentMonth();
    return getExpensesForMonth(currentMonth).isNotEmpty;
  }

  /// Get available months that have expense data
  List<String> get availableMonths {
    final months = <String>{};
    for (final expense in allExpenses) {
      final ym = '${expense.createdAt.year}-${expense.createdAt.month.toString().padLeft(2, '0')}';
      months.add(ym);
    }
    final sortedMonths = months.toList()..sort((a, b) => b.compareTo(a)); // Newest first
    return sortedMonths;
  }

  /// Switch to current month (useful for "Go to Current Month" functionality)
  void switchToCurrentMonth() {
    final currentMonth = _configService.getCurrentMonth();
    updateMonth(currentMonth);
  }

  /// Check if viewing current month
  bool get isViewingCurrentMonth {
    return selectedMonth.value == _configService.getCurrentMonth();
  }

  Future<bool> addExpense({
    required double amount,
    required String category,
    String note = '',
    DateTime? date,
    String? month,
  }) async {
    try {
      isLoading.value = true;
      final newExpense = await _expenseService.createExpense(
        amount: amount,
        category: category,
        note: note,
        date: date,
        month: month,
      );

      // Insert into both lists and re-apply filter
      allExpenses.insert(0, newExpense);
      
      // If the new expense is for the currently selected month, it will appear instantly
      applyMonthFilter();

      // Instantly reflect in Home recent transactions list
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        String displayTitle = category.isNotEmpty ? category : (note.isNotEmpty ? note : 'Expense');
        if (category.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(category)) {
          displayTitle = note.isNotEmpty ? note : 'Expense';
        }
        home.addTransaction(
          displayTitle,
          amount.toStringAsFixed(2),
          false,
        );
        // Refresh home data to reflect new totals
        await home.fetchBudgetData();
        await home.fetchRecentTransactions();
      }

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to add expense: ${e.toString()}';
      print('Error adding expense: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateExpenseItem({
    required String id,
    double? amount,
    String? category,
    String? note,
  }) async {
    try {
      isLoading.value = true;
      final updatedExpense = await _expenseService.updateExpense(
        id: id,
        amount: amount,
        category: category,
        note: note,
      );

      final indexAll = allExpenses.indexWhere((expense) => expense.id == id);
      if (indexAll != -1) {
        allExpenses[indexAll] = updatedExpense;
      }
      applyMonthFilter();
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update expense: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteExpenseItem(String id) async {
    try {
      isLoading.value = true;
      final success = await _expenseService.deleteExpense(id);
      if (success) {
        allExpenses.removeWhere((expense) => expense.id == id);
        applyMonthFilter();
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Failed to delete expense: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  double get totalAmount {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  List<ExpenseItem> getExpensesByCategory(String category) {
    return expenses.where((expense) => expense.category == category).toList();
  }

  void clearError() {
    errorMessage.value = '';
  }

  /// Reset controller state to avoid showing stale data after auth changes
  void reset() {
    try {
      isLoading.value = false;
      errorMessage.value = '';
      allExpenses.clear();
      expenses.clear();
      final currentMonth = _configService.getCurrentMonth();
      selectedMonth.value = currentMonth;
      lastKnownMonth.value = currentMonth;
    } catch (_) {
      // swallow any errors; reset should be safe
    }
  }
}