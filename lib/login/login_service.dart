// services/login_service.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/services/token_service.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/home/home_controller.dart';
import 'package:your_expense/Analytics/expense_controller.dart';

import 'dart:convert';

import 'login_controller/error_response_model.dart';
import 'login_controller/login_request_model.dart';



class LoginService extends GetxService {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _config = Get.find();
  TokenService? _tokenService;

  final RxBool isLoggedIn = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  Future<LoginService> init() async {
    await _ensureTokenServiceReady();
    await loadUserData();
    return this;
  }

  Future<void> _ensureTokenServiceReady() async {
    if (Get.isRegistered<TokenService>()) {
      _tokenService = Get.find<TokenService>();
      if (_tokenService!.isInitialized.value != true) {
        await _tokenService!.init();
      }
    } else {
      _tokenService = Get.put(TokenService());
      await _tokenService!.init();
    }
  }

  Future<void> loadUserData() async {
    try {
      if (_tokenService == null) {
        await _ensureTokenServiceReady();
      }
      final prefs = await SharedPreferences.getInstance();
      final storedUserJson = prefs.getString('user_data');

      if (storedUserJson != null) {
        final userMap = json.decode(storedUserJson);
        currentUser.value = UserModel.fromJson(userMap);
        isLoggedIn.value = _tokenService!.isTokenValid();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final loginRequest = LoginRequestModel(email: email, password: password);

      // Use the centralized login endpoint from ConfigService
      final response = await _apiService.request(
        'POST',
        _config.loginEndpoint,
        body: loginRequest.toJson(),
        requiresAuth: false,
      );

      final loginResponse = LoginResponseModel.fromJson(response);

      if (loginResponse.success) {
        // Extract token from response
        final String jwtToken = loginResponse.data;

        // Decode the JWT token to get user info
        final Map<String, dynamic> payload = _decodeJwtPayload(jwtToken);
        final user = UserModel(
          id: payload['id']?.toString() ?? '',
          email: payload['email']?.toString() ?? '',
          role: payload['role']?.toString() ?? '',
        );

        // Store token using TokenService - FIXED THIS LINE
        await _ensureTokenServiceReady();
        await _tokenService!.saveToken(jwtToken);

        // Store user info
        await _storeUserData(user);

        // Update reactive values
        currentUser.value = user;
        isLoggedIn.value = true;

        return response  ;
      } else {
        throw Exception(loginResponse.message);
      }
    } catch (e) {
      print('Login error: $e');

      // Enhanced error handling for HTTP errors
      if (e is HttpException) {
        try {
          final errorJson = json.decode(e.message);
          if (errorJson is Map<String, dynamic>) {
            final errorResponse = ErrorResponseModel.fromJson(errorJson);
            throw Exception(errorResponse.getFormattedErrorMessage());
          }
        } catch (parseError) {
          print('Error parsing error response: $parseError');
          // Fallback to generic error messages based on status code
          if (e.statusCode == 400) {
            throw Exception('Invalid email or password');
          } else if (e.statusCode == 401) {
            throw Exception('Unauthorized access');
          } else if (e.statusCode == 404) {
            throw Exception('User not found');
          } else if (e.statusCode == 500) {
            throw Exception('Server error. Please try again later.');
          } else {
            throw Exception('Login failed. Please try again.');
          }
        }
      }

      // For other types of exceptions
      rethrow;
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  }

  Future<void> _storeUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(user.toJson()));
    } catch (e) {
      print('Error storing user data: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _ensureTokenServiceReady();
      await _tokenService!.clearToken();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');

      // Also reset subscription state to avoid carrying over premium flags
      try {
        if (Get.isRegistered<SubscriptionService>()) {
          await Get.find<SubscriptionService>().reset();
        }
      } catch (e) {
        print('Warn: failed to reset SubscriptionService on logout: $e');
      }

      currentUser.value = null;
      isLoggedIn.value = false;

      // Clear UI controllers to avoid showing previous user's data
      try {
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().reset();
        }
      } catch (e) {
        print('Warn: failed to reset HomeController on logout: $e');
      }
      try {
        if (Get.isRegistered<ExpenseController>()) {
          Get.find<ExpenseController>().reset();
        }
      } catch (e) {
        print('Warn: failed to reset ExpenseController on logout: $e');
      }
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  bool isTokenExpired() {
    if (_tokenService == null) return true;
    if (!_tokenService!.isTokenValid()) return true;

    try {
      final token = _tokenService!.getToken();
      if (token == null) return true;

      final payload = _decodeJwtPayload(token);
      final expiration = payload['exp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return expiration <= currentTime;
    } catch (e) {
      return true;
    }
  }
}