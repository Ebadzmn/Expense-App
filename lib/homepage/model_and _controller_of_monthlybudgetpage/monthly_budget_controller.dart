import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:your_expense/homepage/model/budget.dart';
import '../../home/home_controller.dart';
import '../../services/api_base_service.dart';
import '../../services/category_service.dart';
import '../../services/config_service.dart';
import '../../services/currency_service.dart';
import '../../services/token_service.dart';


class MonthlyBudgetController extends GetxService {
  final ApiBaseService _apiBaseService = Get.find();
  final ConfigService _configService = Get.find();
  final CurrencyService _currencyService = Get.find();

  // Observable variables for state management
  final isLoading = false.obs;
  final isSettingBudget = false.obs;
  final errorMessage = ''.obs;
  final currentBudget = Rx<Budget?>(null);
  final simpleMonthlyAmount = RxnDouble();
  
  // Selected category for budgeting
  final selectedCategory = RxnString();
  final customCategoryName = RxnString();
  
  // Categories list for selection
  final availableCategories = <Map<String, dynamic>>[
    {'name': 'Food', 'icon': 'assets/icons/food.png'}, // Placeholder paths
    {'name': 'Transport', 'icon': 'assets/icons/transport.png'},
    {'name': 'Groceries', 'icon': 'assets/icons/grocery.png'},
    {'name': 'Eating Out', 'icon': 'assets/icons/eating_out.png'},
    {'name': 'Home', 'icon': 'assets/icons/home.png'},
    {'name': 'Travel', 'icon': 'assets/icons/travel.png'},
    {'name': 'Medicine', 'icon': 'assets/icons/medicine.png'},
    {'name': 'Other', 'icon': 'assets/icons/money.png'},
    // Add more as needed or fetch from API
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadAvailableCategories();
    // Only fetch budget when authenticated
    if (Get.isRegistered<TokenService>()) {
      final tokenService = Get.find<TokenService>();
      if (tokenService.isTokenValid()) {
        fetchMonthlyBudget();
        fetchSimpleMonthlyBudget();
      } else {
        print('MonthlyBudgetController: Skipping initial budget fetch; user not authenticated.');
      }
    } else {
      print('MonthlyBudgetController: TokenService not registered; skipping initial budget fetch.');
    }
  }

  Future<void> loadAvailableCategories({
    String? selectName,
    String? selectIconPath,
  }) async {
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];

    void addOne({
      required String name,
      String? icon,
    }) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        return;
      }
      final key = trimmed.toLowerCase();
      if (!seen.add(key)) {
        return;
      }
      merged.add({
        'name': trimmed,
        if (icon != null && icon.isNotEmpty) 'icon': icon,
      });
    }

    for (final item in availableCategories) {
      addOne(
        name: (item['name'] ?? '').toString(),
        icon: item['icon']?.toString(),
      );
    }

    final tokenOk = Get.isRegistered<TokenService>() &&
        Get.find<TokenService>().isTokenValid() == true;

    if (tokenOk && Get.isRegistered<CategoryService>()) {
      final service = Get.find<CategoryService>();
      final apiCategories = await service.fetchCategoriesWithIcons();
      for (final item in apiCategories) {
        addOne(
          name: (item['name'] ?? '').toString(),
          icon: item['iconPath']?.toString(),
        );
      }
    }

    if (selectName != null && selectName.trim().isNotEmpty) {
      final key = selectName.trim().toLowerCase();
      if (!seen.contains(key)) {
        addOne(name: selectName, icon: selectIconPath);
      }
    }

    availableCategories.assignAll(merged);

    if (selectName != null && selectName.trim().isNotEmpty) {
      for (final item in availableCategories) {
        final n = (item['name'] ?? '').toString();
        if (n.trim().toLowerCase() == selectName.trim().toLowerCase()) {
          selectedCategory.value = n;
          break;
        }
      }
    }
  }

  void addCustomCategoryToAvailableList(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    customCategoryName.value = trimmed;

    final hasOther = availableCategories.any((c) {
      final n = (c['name'] ?? '').toString().trim().toLowerCase();
      return n == 'other';
    });
    if (!hasOther) {
      availableCategories.add({'name': 'Other'});
    }
  }

  String getCustomOtherLabel() {
    final v = customCategoryName.value?.trim();
    if (v == null || v.isEmpty) {
      return 'Other';
    }
    return 'Other ($v)';
  }

  void applyBudgetCategoryAmountsFromApi(dynamic data) {
    if (data is! Map) {
      return;
    }

    final existing = currentBudget.value;
    if (existing == null) {
      return;
    }

    final rawCategories = data['categories'];
    if (rawCategories is! List) {
      return;
    }

    final existingById = <String, BudgetCategory>{};
    final existingByCategory = <String, BudgetCategory>{};
    for (final c in existing.categories) {
      final id = c.id?.trim();
      if (id != null && id.isNotEmpty) {
        existingById[id] = c;
      }
      final key = c.categoryId.trim().toLowerCase();
      if (key.isNotEmpty) {
        existingByCategory[key] = c;
      }
    }

    BudgetCategory mergedCategoryFromJson(Map<String, dynamic> json) {
      final parsed = BudgetCategory.fromJson(json);

      final byId = parsed.id != null ? existingById[parsed.id!] : null;
      final byName = parsed.categoryId.trim().isNotEmpty
          ? existingByCategory[parsed.categoryId.trim().toLowerCase()]
          : null;
      final prev = byId ?? byName;

      final spent = prev?.spent ?? 0.0;
      final remainingRaw = parsed.budgetAmount - spent;
      final remaining = remainingRaw >= 0 ? remainingRaw : 0.0;
      final percentageUsed =
          parsed.budgetAmount <= 0 ? 0.0 : ((spent / parsed.budgetAmount) * 100.0);

      return BudgetCategory(
        categoryId: parsed.categoryId,
        id: parsed.id ?? prev?.id,
        budgetAmount: parsed.budgetAmount,
        spent: spent,
        remaining: remaining,
        percentageUsed: percentageUsed,
        status: prev?.status ?? parsed.status,
      );
    }

    final merged = <BudgetCategory>[];
    for (final item in rawCategories) {
      if (item is Map) {
        merged.add(mergedCategoryFromJson(Map<String, dynamic>.from(item)));
      }
    }

    final updatedTotalCategoryAmount =
        double.tryParse(data['totalCategoryAmount']?.toString() ?? '') ?? existing.totalCategoryAmount;

    currentBudget.value = Budget(
      month: (data['month']?.toString().trim().isNotEmpty == true) ? data['month'].toString() : existing.month,
      totalIncome: existing.totalIncome,
      totalBudget: existing.totalBudget,
      totalCategoryAmount: updatedTotalCategoryAmount,
      effectiveTotalBudget: existing.effectiveTotalBudget,
      totalExpense: existing.totalExpense,
      totalRemaining: existing.totalRemaining,
      totalPercentageUsed: existing.totalPercentageUsed,
      totalPercentageLeft: existing.totalPercentageLeft,
      categories: merged.isNotEmpty ? merged : existing.categories,
    );
  }

  void removeBudgetCategoryLocallyById(String id) {
    final existing = currentBudget.value;
    if (existing == null) {
      return;
    }
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final nextCategories = existing.categories.where((c) => c.id != trimmed).toList();
    if (nextCategories.length == existing.categories.length) {
      return;
    }

    final updatedTotalCategoryAmount = nextCategories.fold<double>(
      0.0,
      (sum, c) => sum + c.budgetAmount,
    );

    currentBudget.value = Budget(
      month: existing.month,
      totalIncome: existing.totalIncome,
      totalBudget: existing.totalBudget,
      totalCategoryAmount: updatedTotalCategoryAmount,
      effectiveTotalBudget: existing.effectiveTotalBudget,
      totalExpense: existing.totalExpense,
      totalRemaining: existing.totalRemaining,
      totalPercentageUsed: existing.totalPercentageUsed,
      totalPercentageLeft: existing.totalPercentageLeft,
      categories: nextCategories,
    );
  }

  // Get current month in required format
  String getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // Format currency for display
  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: _currencyService.currencySymbol.value,
    );
    return formatter.format(amount);
  }

  // Fetch current monthly budget
  Future<void> fetchMonthlyBudget() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final monthParam = getCurrentMonth();
      print('🔍 Fetching budget for month: $monthParam');

      final response = await _apiBaseService.request(
        'GET',
        _configService.getBudgetEndpoint(monthParam),
        requiresAuth: true,
      );

      print('📥 Fetch Response: $response');

      if (response['success'] == true) {
        if (response['data'] != null) {
          print('📦 Raw Data: ${response['data']}');
          try {
            final budget = Budget.fromJson(response['data']);
            currentBudget.value = budget;
            print('✅ Budget parsed successfully. Categories count: ${budget.categories.length}');
          } catch (e) {
             print('❌ Error parsing Budget object: $e');
             errorMessage.value = 'Error parsing budget data';
          }
        }
        print('✅ Budget fetched successfully');
      } else {
        final msg = response['message'] ?? 'Failed to fetch monthly budget';
        // Only set error if it's not a "no budget" or "not found" type message
        if (!msg.toLowerCase().contains('no budget') &&
            !msg.toLowerCase().contains('not found') &&
            !msg.toLowerCase().contains('month parameter')) {
          errorMessage.value = msg;
        }
        print('⚠️ No budget found for this month');
      }
    } on HttpException catch (e) {
      print('❌ Fetch budget HTTP error: ${e.statusCode} - ${e.message}');
      if (e.statusCode != 404) {
        errorMessage.value = 'Error fetching budget: ${e.message}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching budget: ${e.toString()}';
      print('❌ Fetch budget error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch simple monthly budget amount
  Future<void> fetchSimpleMonthlyBudget() async {
    try {
      final monthParam = getCurrentMonth();
      print('🔍 Fetching simple monthly budget for: $monthParam');
      final response = await _apiBaseService.request(
        'GET',
        _configService.getMonthlyBudgetSimpleEndpoint(monthParam),
        requiresAuth: true,
      );
      print('📥 Simple Budget Response: $response');
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final amt = double.tryParse(data['amount']?.toString() ?? '0');
        simpleMonthlyAmount.value = amt;
        print('✅ Simple monthly amount set: $amt');
      } else {
        print('⚠️ Simple monthly budget not available');
      }
    } catch (e) {
      print('❌ Error fetching simple monthly budget: $e');
    }
  }

  // Reset controller state to avoid showing stale data after auth changes
  void reset() {
    try {
      isLoading.value = false;
      isSettingBudget.value = false;
      errorMessage.value = '';
      currentBudget.value = null;
      simpleMonthlyAmount.value = null;
      selectedCategory.value = null;
      customCategoryName.value = null;
    } catch (_) {
      // safe reset
    }
  }

  // Set monthly budget (category wise or general if backend supports)
  Future<bool> setMonthlyBudget(double budgetAmount) async {
    try {
      isSettingBudget.value = true;
      errorMessage.value = '';

      if (selectedCategory.value == null) {
         errorMessage.value = 'Please select a category first';
         return false;
      }

      final selected = selectedCategory.value;
      if (selected == null) {
        errorMessage.value = 'Please select a category first';
        return false;
      }

      final String categoryForApi;
      if (selected.trim().toLowerCase() == 'other' &&
          customCategoryName.value != null &&
          customCategoryName.value!.trim().isNotEmpty) {
        categoryForApi = customCategoryName.value!.trim();
      } else {
        categoryForApi = selected;
      }

      // Debug the request
      final requestBody = {
        'amount': budgetAmount,
        'category': categoryForApi,
      };

      print('📤 Setting budget with body: $requestBody');

      final postResponse = await _apiBaseService.request(
        'POST',
        _configService.monthlyBudgetEndpoint,
        body: requestBody,
        requiresAuth: true,
      );

      print('📨 POST Response: $postResponse');

      if (postResponse['success'] == true) {
        // Refresh to get updated totals and lists
        await fetchMonthlyBudget();
        await fetchSimpleMonthlyBudget();

        // Propagate to HomeController so the main home page updates instantly
        if (Get.isRegistered<HomeController>()) {
          try {
            final home = Get.find<HomeController>();
            if (currentBudget.value != null) {
               home.monthlyBudget.value = currentBudget.value!.totalBudget;
            }
            // Optionally refresh aggregates in the background
            home.fetchBudgetData();
          } catch (e) {
            print('ℹ️ HomeController update failed: $e');
          }
        }

        print('✅ Budget set successfully');
        return true;
      } else {
        errorMessage.value = postResponse['message'] ?? 'Failed to set monthly budget';
        print('❌ Set budget failed: ${errorMessage.value}');
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Server error occurred. Please try again later.';
      print('❌ Set budget error: $e');
      return false;
    } finally {
      isSettingBudget.value = false;
    }
  }

  Future<bool> setMonthlyBudgetWithoutCategory(double budgetAmount) async {
    try {
      isSettingBudget.value = true;
      errorMessage.value = '';

      final requestBody = {
        'amount': budgetAmount,
      };

      final postResponse = await _apiBaseService.request(
        'POST',
        _configService.monthlyBudgetEndpoint,
        body: requestBody,
        requiresAuth: true,
      );

      if (postResponse is Map && postResponse['success'] == true) {
        await fetchMonthlyBudget();
        await fetchSimpleMonthlyBudget();

        if (Get.isRegistered<HomeController>()) {
          try {
            final home = Get.find<HomeController>();
            if (currentBudget.value != null) {
              home.monthlyBudget.value = currentBudget.value!.totalBudget;
            }
            home.fetchBudgetData();
          } catch (e) {
            print('ℹ️ HomeController update failed: $e');
          }
        }

        return true;
      }

      errorMessage.value =
          (postResponse is Map ? postResponse['message'] : null) ?? 'Failed to set monthly budget';
      return false;
    } catch (e) {
      errorMessage.value = 'Server error occurred. Please try again later.';
      return false;
    } finally {
      isSettingBudget.value = false;
    }
  }

  Future<bool> updateCategoryBudget({
    required String id,
    required double amount,
  }) async {
    try {
      isSettingBudget.value = true;
      errorMessage.value = '';

      final requestBody = {
        '_id': id,
        'amount': amount,
      };

      final month =
          (currentBudget.value?.month.trim().isNotEmpty == true) ? currentBudget.value!.month : getCurrentMonth();
      final response = await _apiBaseService.request(
        'PUT',
        _configService.getBudgetEndpoint(month),
        body: requestBody,
        requiresAuth: true,
      );

      if (response is Map && response['success'] == true) {
        if (response['data'] is Map) {
          applyBudgetCategoryAmountsFromApi(response['data']);
        } else {
          await fetchMonthlyBudget();
        }
        await fetchSimpleMonthlyBudget();

        if (Get.isRegistered<HomeController>()) {
          final home = Get.find<HomeController>();
          if (currentBudget.value != null) {
            home.monthlyBudget.value = currentBudget.value!.totalBudget;
          }
          home.fetchBudgetData();
        }

        return true;
      }

      errorMessage.value =
          (response is Map ? response['message'] : null) ?? 'Failed to update budget';
      return false;
    } catch (e) {
      errorMessage.value = 'Server error occurred. Please try again later.';
      return false;
    } finally {
      isSettingBudget.value = false;
    }
  }

  Future<bool> deleteCategoryBudget({required String id}) async {
    try {
      isSettingBudget.value = true;
      errorMessage.value = '';

      final month =
          (currentBudget.value?.month.trim().isNotEmpty == true) ? currentBudget.value!.month : getCurrentMonth();
      final response = await _apiBaseService.request(
        'DELETE',
        _configService.getBudgetEndpoint(month),
        body: {
          '_id': id,
        },
        requiresAuth: true,
      );

      if (response is Map && (response['success'] == true || response.isEmpty)) {
        if (response['data'] is Map) {
          applyBudgetCategoryAmountsFromApi(response['data']);
        } else {
          removeBudgetCategoryLocallyById(id);
          try {
            await fetchMonthlyBudget();
          } catch (_) {}
        }
        await fetchSimpleMonthlyBudget();

        if (Get.isRegistered<HomeController>()) {
          final home = Get.find<HomeController>();
          if (currentBudget.value != null) {
            home.monthlyBudget.value = currentBudget.value!.totalBudget;
          } else {
            home.monthlyBudget.value = 0.0;
          }
          home.fetchBudgetData();
        }

        return true;
      }

      errorMessage.value =
          (response is Map ? response['message'] : null) ?? 'Failed to delete budget';
      return false;
    } catch (e) {
      errorMessage.value = 'Server error occurred. Please try again later.';
      return false;
    } finally {
      isSettingBudget.value = false;
    }
  }
}
