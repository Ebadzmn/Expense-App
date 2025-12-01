// marketplace_service.dart
import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

class MarketplaceService extends GetxService {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _config = Get.find();

  Future<MarketplaceService> init() async {
    print('✅ MarketplaceService initialized');
    return this;
  }

  Future<Map<String, dynamic>> searchProducts({
    required String productName,
    required double maxPrice,
  }) async {
    try {
      print('🔍 Searching products: $productName, Max Price: $maxPrice');

      final response = await _apiService.request(
        'GET',
        '${_config.baseUrl}/marketplace/search',
        queryParams: {
          'product': productName,
          'price': maxPrice.toString(),
        },
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Error searching products: $e');
      rethrow;
    }
  }

  // Add new method for savings API
  Future<Map<String, dynamic>> createSavingsRecord({
    required String category,
    required double initialPrice,
    required double actualPrice,
  }) async {
    try {
      print('💰 Creating savings record: $category, Initial: $initialPrice, Actual: $actualPrice');

      final response = await _apiService.request(
        'POST',
        '${_config.baseUrl}/savings',
        body: {
          'category': category,
          'initialPrice': initialPrice,
          'actualPrice': actualPrice,
        },
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('❌ Error creating savings record: $e');
      rethrow;
    }
  }

  // Helper method to normalize different API response formats
  List<dynamic> normalizeApiResponse(Map<String, dynamic> response) {
    final List<dynamic> normalizedDeals = [];

    if (response['success'] == true) {
      final data = response['data'];

      // Handle Format 1: Generic search results
      if (data.containsKey('generic') && data['generic'] is List) {
        final genericDeals = data['generic'] as List<dynamic>;
        for (var deal in genericDeals) {
          normalizedDeals.add({
            'siteName': deal['siteName'] ?? 'Unknown Site',
            'title': deal['productTitle'] ?? '',
            'price': deal['productPrice'] ?? 0.0,
            'image': '', // Generic format doesn't have images
            'rating': 0.0, // Generic format doesn't have ratings
            'url': deal['productLink'] ?? '',
            'type': 'generic',
          });
        }
      }

      // Handle Format 2: Platform-specific results (Amazon, eBay, etc.)
      else {
        data.forEach((platform, deals) {
          if (deals is List && deals.isNotEmpty) {
            for (var deal in deals) {
              normalizedDeals.add({
                'siteName': _capitalizePlatformName(platform),
                'title': deal['title'] ?? '',
                'price': (deal['price'] ?? 0.0).toDouble(),
                'image': deal['image'] ?? '',
                'rating': (deal['rating'] ?? 0.0).toDouble(),
                'url': deal['url'] ?? '',
                'type': 'specific',
                'itemId': deal['itemId'] ?? '',
              });
            }
          }
        });
      }
    }

    print('🔄 Normalized ${normalizedDeals.length} deals from API response');
    return normalizedDeals;
  }

  String _capitalizePlatformName(String platform) {
    if (platform.isEmpty) return platform;
    return platform[0].toUpperCase() + platform.substring(1);
  }
}