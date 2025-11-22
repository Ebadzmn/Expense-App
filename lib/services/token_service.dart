import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService extends GetxService {
  static TokenService get to => Get.find();
  SharedPreferences? _prefs;
  final RxBool isInitialized = false.obs;

  // Cached token data to avoid repeated decoding and log spam
  String? _cachedToken;
  Map<String, dynamic>? _cachedPayload;
  int? _cachedExp;
  String? _cachedUserId;

  Future<TokenService> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      isInitialized.value = true;
      if (kDebugMode) {
        debugPrint('✅ TokenService initialized');
      }
      // Preload cache if token exists
      final token = _prefs?.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        _cacheTokenData(token);
        if (kDebugMode) {
          debugPrint('📋 Token exists at init. Valid: ${isTokenValid()}');
        }
      }
      return this;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TokenService initialization failed: $e');
      }
      rethrow;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await _prefs?.setString('auth_token', token);
      _cacheTokenData(token);
      if (kDebugMode) {
        debugPrint('✅ Token saved successfully (len=${token.length})');
        debugToken();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving token: $e');
      }
      rethrow;
    }
  }

  String? getToken() {
    try {
      // Prefer cached token; fallback to storage
      if (_cachedToken != null) return _cachedToken;
      final token = _prefs?.getString('auth_token');
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('📋 No token found in storage');
        }
        return null;
      }
      _cacheTokenData(token);
      if (kDebugMode) {
        debugPrint('📋 Retrieved token from storage');
      }
      return _cachedToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error retrieving token: $e');
      }
      return null;
    }
  }

  bool isTokenValid() {
    try {
      final token = getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('❌ Token is null or empty');
        return false;
      }

      // Use cached exp if available; decode once otherwise
      if (_cachedExp == null) {
        _cacheTokenData(token);
      }
      final exp = _cachedExp;
      if (exp == null) {
        // No expiration => treat as valid
        return true;
      }
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isValid = exp > currentTime;
      if (kDebugMode) {
        debugPrint('📋 Token valid: $isValid');
      }
      return isValid;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Token validation error: $e');
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
      if (kDebugMode) {
        debugPrint('📋 Decoded payload');
      }
      return json.decode(decodedString);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Payload decoding error: $e');
      return {};
    }
  }

  Map<String, dynamic>? getTokenPayload() {
    try {
      if (_cachedPayload != null) return _cachedPayload;
      final token = getToken();
      if (token == null) return null;
      _cacheTokenData(token);
      return _cachedPayload;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Token payload decoding error: $e');
      return null;
    }
  }

  String? getUserId() {
    try {
      if (_cachedUserId != null) return _cachedUserId;
      final payload = getTokenPayload();
      if (payload == null) return null;
      _cachedUserId = payload['id']?.toString() ??
          payload['userId']?.toString() ??
          payload['sub']?.toString() ??
          payload['user_id']?.toString();
      return _cachedUserId;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _prefs?.remove('auth_token');
      _cachedToken = null;
      _cachedPayload = null;
      _cachedExp = null;
      _cachedUserId = null;
      if (kDebugMode) debugPrint('✅ Token cleared successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearing token: $e');
    }
  }

  void debugToken() {
    if (!kDebugMode) return;
    final token = getToken();
    debugPrint('=== 🔍 TOKEN DEBUG ===');
    debugPrint('Token exists: ${token != null}');
    debugPrint('Token length: ${token?.length}');
    debugPrint('Token valid: ${isTokenValid()}');
    debugPrint('User ID: ${getUserId()}');

    final payload = getTokenPayload();
    if (payload != null) {
      debugPrint('Payload keys: ${payload.keys}');
    }
    debugPrint('=====================');
  }

  bool get isAuthenticated => isTokenValid();

  DateTime? getTokenExpiration() {
    try {
      final exp = _cachedExp ?? getTokenPayload()?['exp'];
      if (exp != null && exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting token expiration: $e');
      return null;
    }
  }

  DateTime? getTokenIssuedAt() {
    try {
      final iat = _cachedPayload?['iat'] ?? getTokenPayload()?['iat'];
      if (iat != null && iat is int) {
        return DateTime.fromMillisecondsSinceEpoch(iat * 1000);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting token issued at: $e');
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
      if (kDebugMode) debugPrint('❌ Error checking token expiration: $e');
      return false;
    }
  }

  // ===== Reset Password Token Management =====
  Future<void> saveResetToken(String token) async {
    try {
      await _prefs?.setString('reset_password_token', token);
      if (kDebugMode) {
        debugPrint('✅ Reset token saved successfully (len=${token.length})');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving reset token: $e');
    }
  }

  String? getResetToken() {
    try {
      final token = _prefs?.getString('reset_password_token');
      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('📋 No reset token found in storage');
        return null;
      }
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error retrieving reset token: $e');
      return null;
    }
  }

  Future<void> clearResetToken() async {
    try {
      await _prefs?.remove('reset_password_token');
      if (kDebugMode) debugPrint('✅ Reset token cleared successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearing reset token: $e');
    }
  }

  int min(int a, int b) => a < b ? a : b;

  void _cacheTokenData(String token) {
    _cachedToken = token;
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = _decodePayload(parts[1]);
        _cachedPayload = payload;
        final exp = payload['exp'];
        _cachedExp = exp is int ? exp : null;
        _cachedUserId = payload['id']?.toString() ??
            payload['userId']?.toString() ??
            payload['sub']?.toString() ??
            payload['user_id']?.toString();
      }
    } catch (_) {
      // Ignore caching errors silently
    }
  }
}