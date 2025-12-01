import 'package:get/get.dart';
import '../services/api_base_service.dart';
import '../services/config_service.dart';

class RegistrationApiService extends ApiBaseService {
  final ConfigService _config = Get.find();

  Future<Map<String, dynamic>> registerUser(Map<String, String> userData) async {
    print('📤 RegistrationApiService: Sending register request to ${_config.registerEndpoint}');
    final response = await request('POST', _config.registerEndpoint, body: userData, requiresAuth: false);
    print('📥 RegistrationApiService: Received response: $response');
    return response;
  }

  @override
  Future<RegistrationApiService> init() async {
    print('✅ RegistrationApiService initialized');
    return this;
  }
}