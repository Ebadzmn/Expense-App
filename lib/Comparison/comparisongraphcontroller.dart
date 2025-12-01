import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

class ComparisonGraphController extends GetxController {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _config = Get.find();

  final RxList<dynamic> savingsData = <dynamic>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // For graph display - can be from API or from direct comparison
  final RxDouble originalPrice = 0.0.obs;
  final RxDouble withToolPrice = 0.0.obs;
  final RxDouble savingsAmount = 0.0.obs;
  final RxString productCategory = 'Product'.obs;

  // Recent purchases (last 2 items)
  final RxList<dynamic> recentPurchases = <dynamic>[].obs;

  // Flag to determine if we're showing specific comparison or all savings
  final RxBool isSpecificComparison = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Check if we have specific comparison data passed from ComparisonPage
    checkForComparisonData();
  }

  void checkForComparisonData() {
    try {
      // Try to get data passed from ComparisonPage
      final comparisonData = Get.arguments;
      if (comparisonData != null && comparisonData is Map<String, dynamic>) {
        // We have specific comparison data
        setComparisonData(comparisonData);
        isSpecificComparison.value = true;
        print('✅ Loaded specific comparison data from arguments');
      } else {
        // No specific data, fetch all savings
        fetchSavingsData();
        isSpecificComparison.value = false;
        print('🔄 No specific data, fetching all savings');
      }
    } catch (e) {
      print('❌ Error checking for comparison data: $e');
      // Fallback to fetching all savings
      fetchSavingsData();
      isSpecificComparison.value = false;
    }
  }

  // Method to set data from ComparisonPage
  void setComparisonData(Map<String, dynamic> data) {
    try {
      originalPrice.value = (data['initialPrice'] ?? 0).toDouble();
      withToolPrice.value = (data['actualPrice'] ?? 0).toDouble();
      savingsAmount.value = (data['savings'] ?? 0).toDouble();
      productCategory.value = data['category']?.toString() ?? 'Product';

      // Also fetch recent purchases for the bottom section
      fetchSavingsData();

      print('✅ Set comparison data for graph:');
      print('   Original: \$${originalPrice.value}');
      print('   With Tool: \$${withToolPrice.value}');
      print('   Savings: \$${savingsAmount.value}');
      print('   Category: ${productCategory.value}');
    } catch (e) {
      print('❌ Error setting comparison data: $e');
      // Fallback to API data
      fetchSavingsData();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSavingsData() async {
    try {
      if (!isSpecificComparison.value) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      print('🔄 Fetching savings data...');

      final response = await _apiService.request(
        'GET',
        _config.savingsEndpoint,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        savingsData.assignAll(data);

        // Only process for graph if we're not showing specific comparison
        if (!isSpecificComparison.value && data.isNotEmpty) {
          processSavingsData(data);
        }

        // Always process recent purchases
        processRecentPurchases(data);

        print('✅ Successfully fetched ${data.length} savings records');
      } else {
        throw Exception('Failed to fetch savings data');
      }
    } catch (e) {
      errorMessage.value = 'Failed to load savings data: ${e.toString()}';
      print('❌ Error fetching savings data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void processSavingsData(List<dynamic> data) {
    if (data.isEmpty) {
      // Set default values if no data
      originalPrice.value = 100.0;
      withToolPrice.value = 75.0;
      savingsAmount.value = 25.0;
      productCategory.value = 'Sample Product';
      return;
    }

    // Use the most recent savings record for the graph
    final latestSavings = data.first;
    originalPrice.value = (latestSavings['initialPrice'] ?? 0).toDouble();
    withToolPrice.value = (latestSavings['actualPrice'] ?? 0).toDouble();
    savingsAmount.value = (latestSavings['savings'] ?? 0).toDouble();
    productCategory.value = latestSavings['category']?.toString() ?? 'Product';
  }

  void processRecentPurchases(List<dynamic> data) {
    if (data.isEmpty) {
      recentPurchases.clear();
      return;
    }

    // Get recent purchases (last 2 items, excluding current comparison if any)
    recentPurchases.assignAll(
        data.take(2).map((item) => _mapToPurchaseItem(item)).toList()
    );
  }

  Map<String, dynamic> _mapToPurchaseItem(dynamic savingsItem) {
    final category = savingsItem['category']?.toString() ?? 'Unknown';
    final categoryName = savingsItem['categoryName']?.toString() ?? category;
    final price = (savingsItem['actualPrice'] ?? 0).toDouble();
    final date = savingsItem['createdAt']?.toString() ?? '';

    // Map category to appropriate icon and color
    final iconInfo = _getCategoryIcon(category);

    return {
      'category': category,
      'categoryName': categoryName,
      'price': price,
      'date': _formatDate(date),
      'iconAsset': iconInfo['icon'],
      'iconColor': iconInfo['color'],
    };
  }

  Map<String, dynamic> _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('paper') || lowerCategory.contains('office')) {
      return {
        'icon': 'assets/icons/Group 23.png',
        'color': Colors.orange,
      };
    } else if (lowerCategory.contains('bluetooth') || lowerCategory.contains('electronic')) {
      return {
        'icon': 'assets/icons/Group 12 (1).png',
        'color': Colors.blue,
      };
    } else if (lowerCategory.contains('phone') || lowerCategory.contains('mobile')) {
      return {
        'icon': 'assets/icons/phone_icon.png',
        'color': Colors.green,
      };
    } else if (lowerCategory.contains('laptop') || lowerCategory.contains('computer')) {
      return {
        'icon': 'assets/icons/laptop_icon.png',
        'color': Colors.purple,
      };
    } else if (lowerCategory.contains('shoe') || lowerCategory.contains('fashion')) {
      return {
        'icon': 'assets/icons/shoe_icon.png',
        'color': Colors.red,
      };
    } else if (lowerCategory.contains('grocery') || lowerCategory.contains('food')) {
      return {
        'icon': 'assets/icons/grocery_icon.png',
        'color': Colors.amber,
      };
    } else {
      // Default icon
      return {
        'icon': 'assets/icons/Group 23.png',
        'color': Colors.grey,
      };
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return '06/06/25, 05:00 PM';

      final dateTime = DateTime.parse(dateString);
      final formattedDate = '${_twoDigits(dateTime.month)}/${_twoDigits(dateTime.day)}/${dateTime.year.toString().substring(2)}, '
          '${_formatTime(dateTime)}';
      return formattedDate;
    } catch (e) {
      return '06/06/25, 05:00 PM';
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12;
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final minute = _twoDigits(dateTime.minute);
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  // Calculate total savings
  double get totalSavings {
    return savingsData.fold(0.0, (sum, item) => sum + ((item['savings'] ?? 0).toDouble()));
  }

  // Get savings percentage for the current data
  double get savingsPercentage {
    if (originalPrice.value == 0) return 0.0;
    return ((originalPrice.value - withToolPrice.value) / originalPrice.value) * 100;
  }
}