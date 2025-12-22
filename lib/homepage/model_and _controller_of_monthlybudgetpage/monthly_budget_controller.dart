import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:your_expense/homepage/model/budget.dart';
import '../../home/home_controller.dart';
import '../../services/api_base_service.dart';
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
  
  // Categories list for selection (static for now as per UI, or could be dynamic)
  final availableCategories = [
    {'name': 'Food', 'icon': 'assets/icons/food.png'}, // Placeholder paths
    {'name': 'Transport', 'icon': 'assets/icons/transport.png'},
    {'name': 'Groceries', 'icon': 'assets/icons/grocery.png'},
    {'name': 'Eating Out', 'icon': 'assets/icons/eating_out.png'},
    {'name': 'Home', 'icon': 'assets/icons/home.png'},
    {'name': 'Travel', 'icon': 'assets/icons/travel.png'},
    {'name': 'Medicine', 'icon': 'assets/icons/medicine.png'},
    // Add more as needed or fetch from API
  ].obs;

  @override
  void onInit() {
    super.onInit();
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

      // Debug the request
      final requestBody = {
        'amount': budgetAmount,
        'category': selectedCategory.value,
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
}
