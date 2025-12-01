// controllers/budget_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/routes/app_routes.dart';

class BudgetController extends GetxController {
  final ApiBaseService _apiService = Get.find<ApiBaseService>();
  final ConfigService _configService = Get.find<ConfigService>();


  var isLoading = true.obs;
  var monthlyBudget = 0.0.obs;
  var errorMessage = ''.obs;

  var budgetDistribution = <BudgetCategory>[].obs;
  var totalExpense = 0.0.obs;
  var totalPercentageUsed = 0.0.obs;
  var isLoadingDistribution = true.obs;
  var distributionErrorMessage = ''.obs;

  var currentMonth = ''.obs;
  var editBudgetAmount = ''.obs;

  // Add these to track if budget exists
  var budgetExists = false.obs;
  var distributionExists = false.obs;

  @override
  void onInit() {
    currentMonth.value = _configService.getCurrentMonth();
    fetchMonthlyBudget();
    fetchBudgetDistribution();
    super.onInit();
  }

  Future<void> fetchMonthlyBudget() async {
    try {
      isLoading(true);
      errorMessage.value = '';
      budgetExists.value = false;

      print('🔄 Fetching monthly budget for: ${currentMonth.value}');

      final response = await _apiService.request(
        'GET',
        _configService.getMonthlyBudgetSimpleEndpoint(currentMonth.value),
        requiresAuth: true,
      );

      print('📦 Monthly Budget RAW API Response: $response');
      print('📦 Response Type: ${response.runtimeType}');

      // Check if response is successful
      if (response is Map<String, dynamic>) {
        if (response['success'] == true) {
          final data = response['data'];
          print('📦 Monthly Budget Data: $data');

          if (data != null && data is Map<String, dynamic>) {
            // Parse the amount - handle both string and number types
            dynamic amount = data['amount'];
            if (amount != null) {
              if (amount is String) {
                monthlyBudget.value = double.tryParse(amount) ?? 0.0;
              } else if (amount is int) {
                monthlyBudget.value = amount.toDouble();
              } else if (amount is double) {
                monthlyBudget.value = amount;
              } else {
                monthlyBudget.value = 0.0;
              }
            } else {
              monthlyBudget.value = 0.0;
            }

            budgetExists.value = true;
            errorMessage.value = '';
            print('✅ Monthly budget fetched: ${monthlyBudget.value} for month: ${data['month']}');
          } else {
            throw Exception('Invalid data format in response');
          }
        } else {
          // API returned success: false
          monthlyBudget.value = 0.0;
          budgetExists.value = false;
          errorMessage.value = response['message'] ?? 'No budget set for this month';
          print('ℹ️ API returned success: false - ${response['message']}');
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      // Handle errors gracefully
      String errorString = e.toString();
      print('❌ Monthly budget fetch error: $e');

      if (errorString.contains('404') ||
          errorString.contains('Budget not found') ||
          errorString.contains('HTTP 404')) {
        monthlyBudget.value = 0.0;
        budgetExists.value = false;
        errorMessage.value = 'No budget set for this month. Please create a budget first.';
        print('ℹ️ Budget not found (normal for new users): ${currentMonth.value}');
      } else {
        errorMessage.value = 'Failed to fetch monthly budget: $e';
      }
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchBudgetDistribution() async {
    try {
      isLoadingDistribution(true);
      distributionErrorMessage.value = '';
      distributionExists.value = false;

      print('🔄 Fetching budget distribution for: ${currentMonth.value}');

      final response = await _apiService.request(
        'GET',
        _configService.getBudgetEndpoint(currentMonth.value),
        requiresAuth: true,
      );

      print('📦 Budget Distribution RAW API Response: $response');
      print('📦 Response Type: ${response.runtimeType}');

      // Check if response is successful
      if (response is Map<String, dynamic>) {
        if (response['success'] == true) {
          final data = response['data'];
          print('📦 Budget Distribution Data: $data');

          if (data != null && data is Map<String, dynamic>) {
            // Parse total values
            totalExpense.value = _parseDouble(data['totalExpense']);
            totalPercentageUsed.value = _parseDouble(data['totalPercentageUsed']);

            // Parse categories
            if (data['categories'] != null && data['categories'] is List) {
              final categories = List<Map<String, dynamic>>.from(data['categories']);
              print('📦 Categories found: ${categories.length}');

              budgetDistribution.assignAll(
                  categories.map((category) => BudgetCategory(
                    categoryId: category['categoryId']?.toString() ?? '',
                    budgetAmount: _parseDouble(category['budgetAmount']),
                    remaining: _parseDouble(category['remaining']),
                    percentageUsed: _parseDouble(category['percentageUsed']),
                  )).toList()
              );

              distributionExists.value = true;
              distributionErrorMessage.value = '';
              print('✅ Budget distribution fetched: ${budgetDistribution.length} categories for month: ${data['month']}');

              // Debug print each category
              for (var category in budgetDistribution) {
                print('📦 Category: ${category.categoryId}, Amount: ${category.budgetAmount}, Used: ${category.percentageUsed}%');
              }
            } else {
              budgetDistribution.clear();
              distributionExists.value = false;
              distributionErrorMessage.value = 'No categories found in budget distribution';
              print('ℹ️ No categories array in response');
            }
          } else {
            throw Exception('Invalid data format in response');
          }
        } else {
          // API returned success: false
          budgetDistribution.clear();
          totalExpense.value = 0.0;
          totalPercentageUsed.value = 0.0;
          distributionExists.value = false;
          distributionErrorMessage.value = response['message'] ?? 'No budget distribution found';
          print('ℹ️ API returned success: false - ${response['message']}');
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      // Handle errors gracefully
      String errorString = e.toString();
      print('❌ Budget distribution fetch error: $e');

      if (errorString.contains('404') ||
          errorString.contains('Budget not found') ||
          errorString.contains('HTTP 404')) {
        budgetDistribution.clear();
        totalExpense.value = 0.0;
        totalPercentageUsed.value = 0.0;
        distributionExists.value = false;
        distributionErrorMessage.value = 'No budget distribution found. Set up your budget categories first.';
        print('ℹ️ Budget distribution not found (normal for new users): ${currentMonth.value}');
      } else {
        distributionErrorMessage.value = 'Failed to fetch budget distribution: $e';
      }
    } finally {
      isLoadingDistribution(false);
    }
  }

  // Helper method to parse double values safely
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> updateMonthlyBudget(double newBudget) async {
    try {
      // Pro gating: Non-Pro users can add budget only once per month.
      // If a budget already exists and user is not active Pro, block second add/edit.
      final sub = Get.find<SubscriptionService>();
      if (!sub.isActivePro && budgetExists.value == true) {
        Get.snackbar(
          'upgrade_title'.tr,
          'upgrade_subtitle'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
        // Navigate to non-pro upsell page for monthly budget
        Get.toNamed(AppRoutes.monthlyBudgetNonPro);
        return;
      }

      isLoading(true);
      errorMessage.value = '';

      print('🔄 Creating/Updating budget: $newBudget for ${currentMonth.value}');

      final response = await _apiService.request(
        'POST',
        _configService.createBudgetEndpoint,
        body: {
          'totalBudget': newBudget,
          'month': currentMonth.value,
        },
        requiresAuth: true,
      );

      print('📦 Create Budget Response: $response');

      if (response is Map<String, dynamic> && response['success'] == true) {
        // Refresh data after successful creation
        await fetchMonthlyBudget();
        await fetchBudgetDistribution();

        Get.snackbar(
          'Success'.tr,
          'Budget created successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Failed to create budget: ${response['message']}');
      }
    } catch (e) {
      errorMessage.value = 'Failed to create budget: $e';
      Get.snackbar(
        'Error'.tr,
        'Failed to create budget: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Method to get category name from ID
  String getCategoryName(String categoryId) {
    final categoryMap = {
      '68acfc0fffc1998f8c72d9c1': 'food'.tr,
      '68ae33e85f040e977f3493e6': 'transport'.tr,
      // Add more category mappings as needed based on your API
    };
    return categoryMap[categoryId] ?? 'Unknown Category';
  }

  // Method to get category icon from ID
  String getCategoryIcon(String categoryId) {
    final iconMap = {
      '68acfc0fffc1998f8c72d9c1': 'assets/icons/soft-drink-01.png',
      '68ae33e85f040e977f3493e6': 'assets/icons/car.png',
      // Add more icon mappings as needed
    };
    return iconMap[categoryId] ?? 'assets/icons/category.png';
  }

  void setEditBudgetAmount(String amount) {
    editBudgetAmount.value = amount;
  }

  // Refresh all data
  Future<void> refreshData() async {
    await fetchMonthlyBudget();
    await fetchBudgetDistribution();
  }

  // Get current month from budget data
  String get displayMonth {
    return currentMonth.value;
  }

  // Check if we have budget data
  bool get hasBudgetData => budgetDistribution.isNotEmpty;
}

class BudgetCategory {
  final String categoryId;
  final double budgetAmount;
  final double remaining;
  final double percentageUsed;

  BudgetCategory({
    required this.categoryId,
    required this.budgetAmount,
    required this.remaining,
    required this.percentageUsed,
  });

  @override
  String toString() {
    return 'BudgetCategory{categoryId: $categoryId, budgetAmount: $budgetAmount, remaining: $remaining, percentageUsed: $percentageUsed}';
  }
}