import 'package:get/get.dart';

class ChangeEmailService extends GetxService {
  final RxString email = ''.obs;

  Future<ChangeEmailService> init() async {
    // Initialize with default or fetched data
    email.value = 'default@example.com'; // Replace with actual fetch logic
    return this;
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      email.value = newEmail; // Update local state
      // Optionally, call an API to persist the change if needed
      // Example: await apiService.request('PATCH', '${configService.userProfileEndpoint}', body: {'email': newEmail});
    } catch (e) {
      print('❌ Email update error: $e');
      rethrow;
    }
  }
}