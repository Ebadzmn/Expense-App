import 'package:get/get.dart';

import '../../services/api_base_service.dart';
import '../../services/config_service.dart';


class UserService extends GetxService {
  final ApiBaseService _apiService = Get.find<ApiBaseService>();
  final ConfigService _configService = Get.find<ConfigService>();

  // Fetch user profile (GET)
  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final response = await _apiService.request(
        'GET',
        _configService.userProfileEndpoint,
        requiresAuth: true,
      );
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      rethrow;
    }
  }

  // Update user profile (PATCH)
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': '$firstName $lastName'.trim(),
      };
      await _apiService.request(
        'PATCH',
        _configService.userProfileEndpoint,
        body: body,
        requiresAuth: true,
      );
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  Future<UserService> init() async {
    print('✅ UserService initialized');
    return this;
  }
}