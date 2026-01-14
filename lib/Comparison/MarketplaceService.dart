// marketplace_service.dart
import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/services/location_service.dart';

class MarketplaceService extends GetxService {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _config = Get.find();
  final LocationService _locationService = Get.find<LocationService>();

  Future<MarketplaceService> init() async {
    print('✅ MarketplaceService initialized');
    return this;
  }

  String _buildCountryParam() {
    final raw = _locationService.country.trim();
    if (raw.isEmpty) {
      return 'US,GB,DE,FR,IN,IT,AU';
    }

    final normalized = raw.toUpperCase();
    const allowed = <String>{'US', 'GB', 'DE', 'FR', 'IN', 'IT', 'AU'};

    if (allowed.contains(normalized)) {
      return normalized;
    }

    if (normalized.contains('INDIA')) return 'IN';
    if (normalized.contains('UNITED STATES') || normalized.contains('USA')) {
      return 'US';
    }
    if (normalized.contains('UNITED KINGDOM') || normalized.contains('UK')) {
      return 'GB';
    }
    if (normalized.contains('GERMANY')) return 'DE';
    if (normalized.contains('FRANCE')) return 'FR';
    if (normalized.contains('ITALY')) return 'IT';
    if (normalized.contains('AUSTRALIA')) return 'AU';

    return 'US,GB,DE,FR,IN,IT,AU';
  }

  Future<Map<String, dynamic>> searchProducts({
    required String productName,
    required double maxPrice,
  }) async {
    try {
      print('🔍 Searching products: $productName, Max Price: $maxPrice');

      final countryParam = _buildCountryParam();
      print('🌍 Using country filter: $countryParam');

      final response = await _apiService.request(
        'GET',
        '${_config.baseUrl}/marketplace/search',
        queryParams: {
          'product': productName,
          'price': maxPrice.toString(),
          'country': countryParam,
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

      if (data.containsKey('generic') && data['generic'] is List) {
        final genericDeals = data['generic'] as List<dynamic>;
        for (var deal in genericDeals) {
          final rawCurrencyCode =
              deal['currencyCode'] ?? deal['currency_code'] ?? deal['currency'];
          final rawCurrencySymbol =
              deal['currencySymbol'] ?? deal['currency_symbol'];
          final String? currencyCode =
              rawCurrencyCode != null ? rawCurrencyCode.toString() : null;
          final String? currencySymbol =
              rawCurrencySymbol != null ? rawCurrencySymbol.toString() : null;

          normalizedDeals.add({
            'siteName': deal['siteName'] ?? 'Unknown Site',
            'title': deal['productTitle'] ?? '',
            'price': deal['productPrice'] ?? 0.0,
            'image': '', // Generic format doesn't have images
            'rating': 0.0, // Generic format doesn't have ratings
            'url': deal['productLink'] ?? '',
            'type': 'generic',
            'currencyCode': currencyCode,
            'currencySymbol': currencySymbol,
          });
        }
      }

      else {
        data.forEach((platform, deals) {
          if (deals is List && deals.isNotEmpty) {
            for (var deal in deals) {
              final rawCurrencyCode =
                  deal['currencyCode'] ?? deal['currency_code'] ?? deal['currency'];
              final rawCurrencySymbol =
                  deal['currencySymbol'] ?? deal['currency_symbol'];
              final String? currencyCode =
                  rawCurrencyCode != null ? rawCurrencyCode.toString() : null;
              final String? currencySymbol =
                  rawCurrencySymbol != null ? rawCurrencySymbol.toString() : null;

              normalizedDeals.add({
                'siteName': _capitalizePlatformName(platform),
                'title': deal['title'] ?? '',
                'price': (deal['price'] ?? 0.0).toDouble(),
                'image': deal['image'] ?? '',
                'rating': (deal['rating'] ?? 0.0).toDouble(),
                'url': deal['url'] ?? '',
                'type': 'specific',
                'itemId': deal['itemId'] ?? '',
                 'currencyCode': currencyCode,
                 'currencySymbol': currencySymbol,
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
