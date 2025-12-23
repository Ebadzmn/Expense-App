import 'package:get/get.dart';
import 'income_model.dart';
import 'income_service.dart';
import 'package:your_expense/services/config_service.dart';
import '../home/home_controller.dart';
import 'package:your_expense/Analytics/analytics_controller.dart';

class IncomeController extends GetxController {
  final IncomeService _incomeService = Get.find();
  final ConfigService _configService = Get.find();

  final RxList<Income> allIncomes = <Income>[].obs;
  final RxList<Income> incomes = <Income>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMore = true.obs;
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
    
    fetchIncomes();
  }

  /// Monitors for month changes and automatically resets to current month
  void _startMonthChangeMonitoring() {
    // Check for month changes
    ever(selectedMonth, (String month) {
      final currentMonth = _configService.getCurrentMonth();
      if (lastKnownMonth.value != currentMonth) {
        // Month has changed, automatically switch to current month
        print('Income: Month changed from ${lastKnownMonth.value} to $currentMonth');
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

  void updateMonth(String month) {
    selectedMonth.value = month;
    fetchIncomes();
  }

  void applyMonthFilter() {
    if (selectedMonth.value.isEmpty) {
      incomes.assignAll(allIncomes);
    } else {
      final filtered = allIncomes.where((income) {
        final ym = '${income.date.year}-${income.date.month.toString().padLeft(2, '0')}';
        return ym == selectedMonth.value;
      }).toList();
      incomes.assignAll(filtered);
    }
    // Sort by date (newest first)
    incomes.sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get incomes for a specific month without changing the current filter
  List<Income> getIncomesForMonth(String month) {
    return allIncomes.where((income) {
      final ym = '${income.date.year}-${income.date.month.toString().padLeft(2, '0')}';
      return ym == month;
    }).toList();
  }

  /// Check if current month has any incomes
  bool get currentMonthHasIncomes {
    final currentMonth = _configService.getCurrentMonth();
    return getIncomesForMonth(currentMonth).isNotEmpty;
  }

  /// Get available months that have income data
  List<String> get availableMonths {
    final months = <String>{};
    // Add months from loaded data
    for (final income in allIncomes) {
      final ym = '${income.date.year}-${income.date.month.toString().padLeft(2, '0')}';
      months.add(ym);
    }
    // Add last 12 months to ensure navigation is possible even if data isn't loaded yet
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      // Logic to handle year rollback correctly
      int year = now.year;
      int month = now.month - i;
      while (month <= 0) {
        month += 12;
        year -= 1;
      }
      final ym = '$year-${month.toString().padLeft(2, '0')}';
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

  Future<void> fetchIncomes({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        isLoading.value = true;
        currentPage.value = 1;
      } else {
        currentPage.value++;
      }

      errorMessage.value = '';

      final response = await _incomeService.getIncomes(
        page: currentPage.value,
        limit: 10,
        month: selectedMonth.value.isNotEmpty ? selectedMonth.value : null,
      );

      if (loadMore) {
        allIncomes.addAll(response.data);
      } else {
        allIncomes.assignAll(response.data);
      }

      // Apply month filter after fetching
      applyMonthFilter();

      hasMore.value = currentPage.value < response.pagination.totalPages;
    } catch (e) {
      errorMessage.value = 'Failed to load incomes: ${e.toString()}';
      if (!loadMore) {
        incomes.clear();
        allIncomes.clear();
      }
      currentPage.value = loadMore ? currentPage.value - 1 : 1;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshIncomes() async {
    await fetchIncomes(loadMore: false);
  }

  Future<void> loadMoreIncomes() async {
    if (!isLoading.value && hasMore.value) {
      await fetchIncomes(loadMore: true);
    }
  }

  Future<void> addIncome({
    required String source,
    required double amount,
    required DateTime date,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final newIncome = await _incomeService.createIncome(
        source: source,
        amount: amount,
        date: date,
      );

      // Insert into both lists and re-apply filter
      allIncomes.insert(0, newIncome);
      
      // If the new income is for the currently selected month, it will appear instantly
      applyMonthFilter();

      // Instantly reflect in Home recent transactions list
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        home.addTransaction(
          source,
          amount.toStringAsFixed(2),
          true, // isIncome = true
        );
        // Refresh home data to reflect new totals
        await home.fetchBudgetData();
        await home.fetchRecentTransactions();
      }
    } catch (e) {
      errorMessage.value = 'Failed to add income: ${e.toString()}';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editIncome({
    required String id,
    String? source,
    double? amount,
    DateTime? date,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final updatedIncome = await _incomeService.updateIncome(
        id: id,
        source: source,
        amount: amount,
        date: date,
      );

      final index = allIncomes.indexWhere((income) => income.id == id);
      if (index != -1) {
        allIncomes[index] = updatedIncome;
        // Re-apply filter to update the displayed list
        applyMonthFilter();
      }

      // Refresh home data to reflect updated totals
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        await home.fetchBudgetData();
        await home.fetchRecentTransactions();
      }
    } catch (e) {
      errorMessage.value = 'Failed to edit income: ${e.toString()}';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeIncome(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _incomeService.deleteIncome(id);
      allIncomes.removeWhere((income) => income.id == id);
      
      // Re-apply filter to update the displayed list
      applyMonthFilter();

      // Refresh home data to reflect updated totals
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        await home.fetchBudgetData();
        await home.fetchRecentTransactions();
      }
    } catch (e) {
      errorMessage.value = 'Failed to delete income: ${e.toString()}';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  double get totalIncome {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  double get totalIncomeForSelectedMonth {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  List<Income> getIncomesByMonth(String month) {
    return allIncomes.where((income) => income.month == month).toList();
  }
}