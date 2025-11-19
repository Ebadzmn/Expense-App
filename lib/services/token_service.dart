import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService extends GetxService {
  static TokenService get to => Get.find();
  SharedPreferences? _prefs;
  final RxBool isInitialized = false.obs;

  Future<TokenService> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      isInitialized.value = true;
      print('✅ TokenService initialized');
      print('📋 Token exists: ${getToken() != null}');
      print('📋 Token valid: ${isTokenValid()}');
      if (getToken() != null) {
        print('📋 User ID: ${getUserId()}');
      }
      return this;
    } catch (e) {
      print('❌ TokenService initialization failed: $e');
      rethrow;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await _prefs?.setString('auth_token', token);
      print('✅ Token saved successfully');
      print('📋 Token length: ${token.length}');
      print('📋 Token preview: ${token.substring(0, min(token.length, 20))}...');
      debugToken();
    } catch (e) {
      print('❌ Error saving token: $e');
      rethrow;
    }
  }

  String? getToken() {
    try {
      final token = _prefs?.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('📋 No token found in storage');
        return null;
      }
      print('📋 Retrieved token: ${token.substring(0, min(token.length, 20))}...');
      return token;
    } catch (e) {
      print('❌ Error retrieving token: $e');
      return null;
    }
  }

  bool isTokenValid() {
    try {
      final token = getToken();
      if (token == null || token.isEmpty) {
        print('❌ Token is null or empty');
        return false;
      }

      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ Invalid JWT format: ${parts.length} parts instead of 3');
        return false;
      }

      final payload = _decodePayload(parts[1]);
      if (payload.isEmpty) {
        print('❌ Failed to decode payload');
        return false;
      }

      final exp = payload['exp'];
      if (exp == null) {
        print('📋 No expiration time in token');
        return true;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isValid = exp > currentTime;

      print('📋 Token expiration: ${DateTime.fromMillisecondsSinceEpoch(exp * 1000)}');
      print('📋 Current time: ${DateTime.now()}');
      print('📋 Token valid: $isValid');

      return isValid;
    } catch (e) {
      print('❌ Token validation error: $e');
      return false;
    }
  }

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      String normalizedPayload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (normalizedPayload.length % 4) {
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decoded = base64Url.decode(normalizedPayload);
      final String decodedString = utf8.decode(decoded);

      print('📋 Decoded payload: $decodedString');
      return json.decode(decodedString);
    } catch (e) {
      print('❌ Payload decoding error: $e');
      return {};
    }
  }

  Map<String, dynamic>? getTokenPayload() {
    try {
      final token = getToken();
      if (token == null) return null;

      final parts = token.split('.');
      if (parts.length != 3) return null;

      return _decodePayload(parts[1]);
    } catch (e) {
      print('❌ Token payload decoding error: $e');
      return null;
    }
  }

  String? getUserId() {
    try {
      final payload = getTokenPayload();
      if (payload == null) return null;

      return payload['id']?.toString() ??
          payload['userId']?.toString() ??
          payload['sub']?.toString() ??
          payload['user_id']?.toString();
    } catch (e) {
      print('❌ Error getting user ID: $e');
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _prefs?.remove('auth_token');
      print('✅ Token cleared successfully');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
  }

  void debugToken() {
    final token = getToken();
    print('=== 🔍 TOKEN DEBUG ===');
    print('Token exists: ${token != null}');
    print('Token length: ${token?.length}');
    print('Token valid: ${isTokenValid()}');
    print('User ID: ${getUserId()}');

    final payload = getTokenPayload();
    if (payload != null) {
      print('Payload keys: ${payload.keys}');
      print('Full payload: $payload');
    }
    print('=====================');
  }

  bool get isAuthenticated => isTokenValid();

  DateTime? getTokenExpiration() {
    try {
      final payload = getTokenPayload();
      final exp = payload?['exp'];
      if (exp != null && exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      return null;
    } catch (e) {
      print('❌ Error getting token expiration: $e');
      return null;
    }
  }

  DateTime? getTokenIssuedAt() {
    try {
      final payload = getTokenPayload();
      final iat = payload?['iat'];
      if (iat != null && iat is int) {
        return DateTime.fromMillisecondsSinceEpoch(iat * 1000);
      }
      return null;
    } catch (e) {
      print('❌ Error getting token issued at: $e');
      return null;
    }
  }

  bool isTokenExpiringSoon() {
    try {
      final expiration = getTokenExpiration();
      if (expiration == null) return false;

      final now = DateTime.now();
      final fiveMinutesFromNow = now.add(Duration(minutes: 5));
      return expiration.isBefore(fiveMinutesFromNow);
    } catch (e) {
      print('❌ Error checking token expiration: $e');
      return false;
    }
  }

  // ===== Reset Password Token Management =====
  Future<void> saveResetToken(String token) async {
    try {
      await _prefs?.setString('reset_password_token', token);
      print('✅ Reset token saved successfully');
      print('📋 Reset token length: ${token.length}');
      print('📋 Reset token preview: ${token.substring(0, min(token.length, 20))}...');
    } catch (e) {
      print('❌ Error saving reset token: $e');
    }
  }

  String? getResetToken() {
    try {
      final token = _prefs?.getString('reset_password_token');
      if (token == null || token.isEmpty) {
        print('📋 No reset token found in storage');
        return null;
      }
      print('📋 Retrieved reset token: ${token.substring(0, min(token.length, 20))}...');
      return token;
    } catch (e) {
      print('❌ Error retrieving reset token: $e');
      return null;
    }
  }

  Future<void> clearResetToken() async {
    try {
      await _prefs?.remove('reset_password_token');
      print('✅ Reset token cleared successfully');
    } catch (e) {
      print('❌ Error clearing reset token: $e');
    }
  }

  int min(int a, int b) => a < b ? a : b;
}