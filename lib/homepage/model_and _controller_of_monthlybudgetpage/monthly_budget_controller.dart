import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  final currentBudget = Rx<Map<String, dynamic>>({"totalBudget": 0.0});

  @override
  void onInit() {
    super.onInit();
    // Only fetch budget when authenticated
    if (Get.isRegistered<TokenService>()) {
      final tokenService = Get.find<TokenService>();
      if (tokenService.isTokenValid()) {
        fetchMonthlyBudget();
      } else {
        print('MonthlyBudgetController: Skipping initial budget fetch; user not authenticated.');
        // Default state without network call
        currentBudget.value = {
          'totalBudget': 0.0,
          'month': getCurrentMonth(),
        };
      }
    } else {
      print('MonthlyBudgetController: TokenService not registered; skipping initial budget fetch.');
      currentBudget.value = {
        'totalBudget': 0.0,
        'month': getCurrentMonth(),
      };
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

      final queryParams = {'Month': getCurrentMonth()}; // Use capital 'M' for Month

      print('🔍 Fetching budget with params: $queryParams');

      final response = await _apiBaseService.request(
        'GET',
        _configService.monthlyBudgetEndpoint,
        queryParams: queryParams,
        requiresAuth: true,
      );

      print('📥 Fetch Response: $response');

      double budget = 0.0;
      String monthStr = getCurrentMonth();

      if (response['success'] == true) {
        if (response['data'] != null) {
          if (response['data']['amount'] != null) {
            budget = (response['data']['amount'] as num).toDouble();
          }
          if (response['data']['month'] != null) {
            monthStr = response['data']['month'];
          }
        }
        print('✅ Budget fetched successfully: totalBudget=$budget, month=$monthStr');
      } else {
        final msg = response['message'] ?? 'Failed to fetch monthly budget';
        // Only set error if it's not a "no budget" or "not found" type message
        if (!msg.toLowerCase().contains('no budget') &&
            !msg.toLowerCase().contains('not found') &&
            !msg.toLowerCase().contains('month parameter')) {
          errorMessage.value = msg;
        }
        print('⚠️ No budget found for this month, defaulting to 0');
      }

      currentBudget.value = {
        'totalBudget': budget,
        'month': monthStr,
      };
    } on HttpException catch (e) {
      print('❌ Fetch budget HTTP error: ${e.statusCode} - ${e.message}');
      if (e.statusCode == 404) {
        // No budget set for this month; treat as normal default
        errorMessage.value = '';
        currentBudget.value = {
          'totalBudget': 0.0,
          'month': getCurrentMonth(),
        };
      } else {
        errorMessage.value = 'Error fetching budget: ${e.message}';
        currentBudget.value = {
          'totalBudget': 0.0,
          'month': getCurrentMonth(),
        };
      }
    } catch (e) {
      errorMessage.value = 'Error fetching budget: ${e.toString()}';
      print('❌ Fetch budget error: $e');
      // On error, default to 0 without showing fetch-specific error if it's param-related
      if (errorMessage.value.toLowerCase().contains('month parameter')) {
        errorMessage.value = '';
      }
      currentBudget.value = {
        'totalBudget': 0.0,
        'month': getCurrentMonth(),
      };
    } finally {
      isLoading.value = false;
    }
  }

  // Set monthly budget and refresh
  Future<bool> setMonthlyBudget(double budgetAmount) async {
    try {
      isSettingBudget.value = true;
      errorMessage.value = '';

      // Debug the request
      final month = getCurrentMonth();
      final requestBody = {
        'amount': budgetAmount, // Use 'amount' as expected by API
        'month': month,
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
        // Update local state immediately
        currentBudget.value = {
          'totalBudget': budgetAmount,
          'month': month,
        };

        // Also fetch to confirm (optional)
        await fetchMonthlyBudget();

        // Propagate to HomeController so the main home page updates instantly
        if (Get.isRegistered<HomeController>()) {
          try {
            final home = Get.find<HomeController>();
            home.monthlyBudget.value = budgetAmount;
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
