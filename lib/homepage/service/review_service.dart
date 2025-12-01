import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

class ReviewService extends GetxService {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _configService = Get.find();

  Future<ReviewService> init() async {
    print('ReviewService initialized');
    return this;
  }

  Future<Map<String, dynamic>> submitReview(int rating, String comment) async {
    try {
      // Use the correct endpoint from config service
      final String endpoint = _configService.reviewEndpoint;
      print('Submitting review to: $endpoint');

      final response = await _apiService.request(
        'POST',
        endpoint,
        body: {
          'rating': rating,
          'comment': comment,
        },
        requiresAuth: true,
      );

      print('Review submission response: $response');

      return response;
    } catch (e) {
      print('Review submission error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReviews({String status = 'all'}) async {
    try {
      // Use the correct endpoint from config service
      final String endpoint = _configService.reviewEndpoint;
      print('Fetching reviews from: $endpoint');

      final response = await _apiService.request(
        'GET',
        endpoint,
        queryParams: {'status': status},
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('Get reviews error: $e');
      rethrow;
    }
  }

  Future<bool> testReviewEndpoint() async {
    try {
      // Use the correct endpoint from config service
      final String endpoint = _configService.reviewEndpoint;
      print('Testing endpoint: $endpoint');

      final response = await _apiService.request(
        'GET',
        endpoint,
        requiresAuth: true,
      );

      print('Review endpoint test successful: $response');
      return true;
    } catch (e) {
      print('Review endpoint test failed: $e');
      return false;
    }
  }
}