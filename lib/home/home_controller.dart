import 'package:get/get.dart';
import 'package:your_expense/homepage/service/budget_service.dart';
import 'package:your_expense/homepage/service/transaction_service.dart';
import 'package:intl/intl.dart';
// Ensure this path is correct
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/Analytics/ExpenseService.dart';
import 'package:your_expense/services/subscription_service.dart';

import '../homepage/model/transaction.dart';
import '../login/login_service.dart';
import '../routes/app_routes.dart';
import '../services/token_service.dart';
import 'package:your_expense/Analytics/analytics_controller.dart';


class HomeController extends GetxController {
  final TransactionService _transactionService = Get.find();
  final BudgetService _budgetService = Get.find();
  final ApiBaseService _apiService = Get.find();
  final ConfigService _configService = Get.find();
  ExpenseService? _expenseService;

  var selectedNavIndex = 0.obs;
  var starRating = 0.obs;

  var availableBalance = 0.0.obs;
  var income = 0.0.obs;
  var expense = 0.0.obs;
  var savings = 0.0.obs;

  var monthlyBudget = 0.0.obs;
  var spentAmount = 0.0.obs;
  var spentPercentage = 0.0.obs;
  var leftAmount = 0.0.obs;
  var leftPercentage = 0.0.obs;

  var recentTransactions = <Transaction>[].obs;
  var isLoading = false.obs;
  // Track whether home data has been loaded at least once after login
  var hasLoadedHomeData = false;

  // Reset all home page state when user changes or logs out
  void reset() {
    availableBalance.value = 0.0;
    income.value = 0.0;
    expense.value = 0.0;
    savings.value = 0.0;

    monthlyBudget.value = 0.0;
    spentAmount.value = 0.0;
    spentPercentage.value = 0.0;
    leftAmount.value = 0.0;
    leftPercentage.value = 0.0;

    recentTransactions.clear();
    hasLoadedHomeData = false;
  }

  @override
  void onInit() {
    super.onInit();
    selectedNavIndex.value = 0;
    // Bind ExpenseService if available
    if (Get.isRegistered<ExpenseService>()) {
      _expenseService = Get.find<ExpenseService>();
    }

    // Subscribe to global Analytics month selection
    if (Get.isRegistered<AnalyticsController>()) {
      final analytics = Get.find<AnalyticsController>();
      // Align immediately with global selected month
      Future(() async {
        final initialMonth = analytics.selectedMonth.value;
        await fetchBudgetData(month: initialMonth);
        await _refreshExpenseFromListForMonth(initialMonth);
      });
      ever<String>(analytics.selectedMonth, (m) async {
        await fetchBudgetData(month: m);
        await _refreshExpenseFromListForMonth(m);
      });
    }

    // Initial fetches after ensuring services are ready
    Future(() async {
      try {
        if (!Get.isRegistered<TokenService>()) {
          print(
            'HomeController: TokenService not registered yet. Skipping initial fetch.',
          );
          return;
        }
        final tokenService = Get.find<TokenService>();
        if (tokenService.isTokenValid()) {
          await fetchBudgetData();
          await fetchRecentTransactions();
          hasLoadedHomeData = true;
        } else {
          print(
            'HomeController: Skipping initial fetch; user not authenticated.',
          );
        }
      } catch (e) {
        print('HomeController onInit error: $e');
      }
    });
  }

  // Ensure home data is loaded when the screen becomes visible after login
  Future<void> ensureHomeDataLoaded() async {
    if (!Get.isRegistered<TokenService>()) {
      print('ensureHomeDataLoaded: TokenService missing; no fetch.');
      return;
    }
    final tokenService = Get.find<TokenService>();
    if (!tokenService.isTokenValid()) {
      print('ensureHomeDataLoaded: user not authenticated; no fetch.');
      return;
    }
    if (hasLoadedHomeData) return;
    await fetchBudgetData();
    await fetchRecentTransactions();
    hasLoadedHomeData = true;
  }

  String getCurrentMonth() {
    final now = DateTime.now();
    final months = [
      'january'.tr,
      'february'.tr,
      'march'.tr,
      'april'.tr,
      'may'.tr,
      'june'.tr,
      'july'.tr,
      'august'.tr,
      'september'.tr,
      'october'.tr,
      'november'.tr,
      'december'.tr,
    ];
    return months[now.month - 1];
  }

  // Helper method to get current month in API format (YYYY-MM)
  String getCurrentMonthForApi() {
    return DateFormat('yyyy-MM').format(DateTime.now());
  }

  Future<void> fetchRecentTransactions() async {
    try {
      isLoading.value = true;
      final transactions = await _transactionService.fetchRecentTransactions();
      recentTransactions.assignAll(transactions);

      // Do not recalculate totals here; monthly totals fetched separately.
    } catch (e) {
      print('Error in fetchRecentTransactions: $e');
      // Error is already handled in TransactionService with Get.snackbar
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBudgetData({String? month}) async {
    try {
      isLoading.value = true;

      // Get selected or current month in API format (YYYY-MM)
      final currentMonth = month ?? getCurrentMonthForApi();

      // Fetch simple monthly budget amount using `simple-monthly-budget?Month=`
      final simpleBudgetAmount = await _budgetService
          .fetchSimpleMonthlyBudgetAmount(month: currentMonth);
      monthlyBudget.value = simpleBudgetAmount;

      // Fetch budget data using the new endpoint with month parameter
      final budget = await _budgetService.fetchMonthlyBudgetData(
        month: currentMonth,
      );
      print(budget);

      // Update budget-related values (prefer server-provided totalBudget)
      monthlyBudget.value = budget.totalBudget;
      spentAmount.value = budget.totalExpense;
      spentPercentage.value = budget.totalPercentageUsed;
      leftAmount.value = budget.totalRemaining;
      leftPercentage.value = budget.totalPercentageLeft;

      // Derive fallbacks when API omits remaining/percentage fields
      try {
        final mb = monthlyBudget.value;
        final spent = spentAmount.value;
        // Left amount fallback
        if (leftAmount.value == 0.0) {
          leftAmount.value = (mb - spent).clamp(0.0, double.infinity);
        }
        // Spent percentage fallback
        if (spentPercentage.value == 0.0) {
          spentPercentage.value = mb > 0.0
              ? ((spent / mb) * 100).clamp(0.0, 100.0)
              : 0.0;
        }
        // Left percentage fallback
        if (leftPercentage.value == 0.0) {
          leftPercentage.value = mb > 0.0
              ? ((leftAmount.value / mb) * 100).clamp(0.0, 100.0)
              : 0.0;
        }
      } catch (e) {
        print('Budget fallback computation failed: $e');
      }

      // Update monthly totals via summary endpoints
      try {
        double monthlyIncome = 0.0;
        double monthlyExpense = 0.0;
        // Prefer lowercase 'month' to match backend, fallback to 'Month'
        final incomeRespLower = await _apiService.request(
          'GET',
          _configService.incomeSummaryEndpoint,
          queryParams: {'month': currentMonth},
          requiresAuth: true,
        );
        Map<String, dynamic>? incomeDataMap;
        if (incomeRespLower is Map<String, dynamic> &&
            incomeRespLower['success'] == true) {
          incomeDataMap = incomeRespLower['data'] as Map<String, dynamic>?;
        } else {
          final incomeRespUpper = await _apiService.request(
            'GET',
            _configService.incomeSummaryEndpoint,
            queryParams: {'Month': currentMonth},
            requiresAuth: true,
          );
          if (incomeRespUpper is Map<String, dynamic> &&
              incomeRespUpper['success'] == true) {
            incomeDataMap = incomeRespUpper['data'] as Map<String, dynamic>?;
          }
        }
        if (incomeDataMap != null && incomeDataMap['totalIncome'] is num) {
          monthlyIncome = (incomeDataMap['totalIncome'] as num).toDouble();
        }

        final expenseRespLower = await _apiService.request(
          'GET',
          '${_configService.baseUrl}/expense/summary',
          queryParams: {'month': currentMonth},
          requiresAuth: true,
        );
        Map<String, dynamic>? expenseDataMap;
        if (expenseRespLower is Map<String, dynamic> &&
            expenseRespLower['success'] == true) {
          expenseDataMap = expenseRespLower['data'] as Map<String, dynamic>?;
        } else {
          final expenseRespUpper = await _apiService.request(
            'GET',
            '${_configService.baseUrl}/expense/summary',
            queryParams: {'Month': currentMonth},
            requiresAuth: true,
          );
          if (expenseRespUpper is Map<String, dynamic> &&
              expenseRespUpper['success'] == true) {
            expenseDataMap = expenseRespUpper['data'] as Map<String, dynamic>?;
          }
        }
        if (expenseDataMap != null && expenseDataMap['totalExpense'] is num) {
          monthlyExpense = (expenseDataMap['totalExpense'] as num).toDouble();
        }

        income.value = monthlyIncome;
        // Use authoritative server total for expense initially
        expense.value = monthlyExpense;
        availableBalance.value = monthlyIncome - expense.value;
      } catch (e) {
        print('Monthly summary fetch failed: $e');
        await _fallbackUpdateMonthlyTotals(currentMonth);
      }

      // Fallback if any monthly value is zero but transactions may exist
      if (income.value == 0.0 || expense.value == 0.0) {
        await _fallbackUpdateMonthlyTotals(currentMonth);
      }

      // Override expense with sum of expense list for the month
      try {
        await _refreshExpenseFromListForMonth(currentMonth);
      } catch (e) {
        print('Expense list sum refresh failed: $e');
      }
    } catch (e) {
      print('Error in fetchBudgetData: $e');
      // Error is already handled in BudgetService with Get.snackbar
    } finally {
      isLoading.value = false;
    }
  }

  // Navigation methods
  void navigateToNotification() {
    Get.toNamed(AppRoutes.notification);
  }

  void navigateToMonthlyBudgetnonpro() {
    Get.toNamed(AppRoutes.monthlyBudgetNonPro);
  }

  void navigateToAddTransaction({required bool isExpense}) {
    final sub = Get.isRegistered<SubscriptionService>()
        ? Get.find<SubscriptionService>()
        : Get.put(SubscriptionService());
    if (sub.isActivePro) {
      Get.toNamed(
        AppRoutes.proExpensesIncome,
        arguments: {
          'defaultTab': isExpense ? 0 : 1,
        },
      );
    } else {
      Get.toNamed(
        AppRoutes.addTransaction,
        arguments: {
          'initialIndex': isExpense ? 0 : 1,
        },
      );
    }
  }

  void navigateToAddProExpense() {
    Get.toNamed(
      AppRoutes.proExpensesIncome,
      arguments: {
        'defaultTab': 0,
      },
    );
  }

  void navigateToAddProIncome() {
    Get.toNamed(
      AppRoutes.proExpensesIncome,
      arguments: {
        'defaultTab': 1,
      },
    );
  }

  void shareExperience() {
    Get.toNamed(AppRoutes.shareExperience);
  }

  void viewAllTransactions() {
    Get.toNamed(
      AppRoutes.allTransactions,
      arguments: recentTransactions.toList(),
    );
  }

  void setStarRating(int rating) {
    starRating.value = rating == starRating.value ? 0 : rating;
  }

  Future<void> changeNavIndex(int index) async {
    if (selectedNavIndex.value == index) return;

    selectedNavIndex.value = index;

    try {
      switch (index) {
        case 0: // Home
          if (Get.currentRoute != AppRoutes.mainHome) {
            Get.toNamed(AppRoutes.mainHome);
          }
          break;
        case 1: // Analytics
          if (Get.currentRoute != AppRoutes.analytics) {
            Get.toNamed(AppRoutes.analytics);
          }
          break;
        case 2: // Comparison (no ads)
          if (Get.currentRoute != AppRoutes.comparison) {
            Get.toNamed(AppRoutes.comparison);
          }
          break;
        case 3: // Settings
          if (Get.currentRoute != AppRoutes.settings) {
            Get.toNamed(AppRoutes.settings);
          }
          break;
        default:
          break;
      }
    } catch (e) {
      print('Error changing navigation index: $e');
    }
  }

  Future<void> _fallbackUpdateMonthlyTotals(String currentMonth) async {
    try {
      // In absence of summary endpoints, derive totals from recent transactions
      double monthlyIncome = 0.0;
      double monthlyExpense = 0.0;
      for (final tx in recentTransactions) {
        final ym = _extractMonthForApi(tx.time);
        if (ym == currentMonth) {
          if (tx.isIncome) {
            monthlyIncome += tx.numericAmount;
          } else {
            monthlyExpense += tx.numericAmount;
          }
        }
      }
      // Fill only missing totals from recent transactions when summary endpoints unavailable
      if (income.value == 0.0) {
        income.value = monthlyIncome;
      }
      if (expense.value == 0.0) {
        expense.value = monthlyExpense;
      }
      availableBalance.value = income.value - expense.value;
    } catch (e) {
      print('Fallback monthly totals failed: $e');
    }
  }

  // Compute expense from full expense list for the given month
  Future<void> _refreshExpenseFromListForMonth(String month) async {
    try {
      List<dynamic> rawList = [];

      if (_expenseService != null) {
        final items = await _expenseService!.getExpenses();
        double total = 0.0;
        for (final e in items) {
          final ym =
              '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}';
          if (ym == month) total += e.amount;
        }
        expense.value = total;
        availableBalance.value = income.value - expense.value;
        return;
      }

      // Fallback: direct API call if ExpenseService not registered
      final response = await _apiService.request(
        'GET',
        _configService.expenseEndpoint,
        requiresAuth: true,
      );

      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          rawList = data;
        } else if (response['expenses'] is List) {
          rawList = response['expenses'];
        } else if (response['items'] is List) {
          rawList = response['items'];
        } else {
          rawList = [];
        }
      }

      double total = 0.0;
      for (final item in rawList.whereType<Map<String, dynamic>>()) {
        try {
          // Parse amount
          final amtRaw = item['amount'];
          double amt = 0.0;
          if (amtRaw is num) {
            amt = amtRaw.toDouble();
          } else if (amtRaw is String) {
            amt = double.tryParse(amtRaw) ?? 0.0;
          }
          // Parse createdAt and compare month
          final createdStr = item['createdAt']?.toString() ?? '';
          DateTime dt;
          try {
            dt = DateTime.parse(createdStr);
          } catch (_) {
            dt = DateTime.now();
          }
          final ym = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          if (ym == month) total += amt;
        } catch (_) {}
      }

      expense.value = total;
      availableBalance.value = income.value - expense.value;
    } catch (e) {
      print('⚠️ _refreshExpenseFromListForMonth failed: $e');
    }
  }

  String _extractMonthForApi(String time) {
    try {
      final dt = DateTime.parse(time);
      return DateFormat('yyyy-MM').format(dt);
    } catch (_) {
      if (time.length >= 7) {
        final m = time.substring(0, 7);
        if (RegExp(r'^\d{4}-\d{2}$').hasMatch(m)) {
          return m;
        }
      }
      return getCurrentMonthForApi();
    }
  }

  void setNavIndex(int index) {
    selectedNavIndex.value = index;
  }

  void addTransaction(String title, String amount, bool isIncome) {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'pm'.tr : 'am'.tr;

    final txn = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: isIncome ? 'income' : 'expense',
      amount: amount,
      time: 'today_time'.trParams({
        'hour': hour,
        'minute': minute,
        'period': period,
      }),
    );

    recentTransactions.insert(0, txn);
    if (recentTransactions.length > 4) {
      recentTransactions.removeLast();
    }

    // Removed direct mutation of income/expense here to avoid mismatch.
    // HomeController now derives expense from the full expense list for the current month.
  }

  void logout() async {
    try {
      selectedNavIndex.value = 0;
      reset();
      if (Get.isRegistered<LoginService>()) {
        final loginService = Get.find<LoginService>();
        await loginService.logout();
      } else {
        Get.find<TokenService>().clearToken();
      }
    } catch (e) {
      print('Logout encountered an error: $e');
      // Ensure token cleared even on error
      if (Get.isRegistered<TokenService>()) {
        Get.find<TokenService>().clearToken();
      }
    } finally {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
