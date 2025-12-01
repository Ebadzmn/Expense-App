// comparison_page_controller.dart
import 'package:get/get.dart';


import 'MarketplaceService.dart';

class ComparisonPageController extends GetxController {
  final MarketplaceService _marketplaceService = Get.find();

  final RxList<dynamic> deals = <dynamic>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString productName = ''.obs;
  final RxDouble maxPrice = 0.0.obs;
  final RxString currentSearchTerm = ''.obs;
  final RxBool isCreatingSavings = false.obs;

  Future<void> searchProducts(String product, double price) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      productName.value = product;
      maxPrice.value = price;
      currentSearchTerm.value = product;

      print('🔄 Starting product search...');

      final response = await _marketplaceService.searchProducts(
        productName: product,
        maxPrice: price,
      );

      if (response['success'] == true) {
        // Use the normalized response method
        final normalizedDeals = _marketplaceService.normalizeApiResponse(response);
        deals.assignAll(normalizedDeals);
        print('✅ Found ${deals.length} deals in normalized format');

        // Debug: Print the structure of first deal
        if (deals.isNotEmpty) {
          print('🔍 First deal structure: ${deals.first}');
        }
      } else {
        throw Exception('Failed to fetch deals');
      }
    } catch (e) {
      errorMessage.value = 'Failed to search products: ${e.toString()}';
      print('❌ Search error: $e');
      deals.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // New method to create savings record
  Future<bool> createSavingsRecord({
    required String category,
    required double initialPrice,
    required double actualPrice,
  }) async {
    try {
      isCreatingSavings.value = true;
      errorMessage.value = '';

      print('💰 Creating savings record...');

      final response = await _marketplaceService.createSavingsRecord(
        category: category,
        initialPrice: initialPrice,
        actualPrice: actualPrice,
      );

      if (response['success'] == true) {
        print('✅ Savings record created successfully');
        print('📊 Savings data: ${response['data']}');
        return true;
      } else {
        throw Exception('Failed to create savings record');
      }
    } catch (e) {
      errorMessage.value = 'Failed to create savings record: ${e.toString()}';
      print('❌ Savings creation error: $e');
      return false;
    } finally {
      isCreatingSavings.value = false;
    }
  }

  void clearResults() {
    deals.clear();
    errorMessage.value = '';
    currentSearchTerm.value = '';
  }
}