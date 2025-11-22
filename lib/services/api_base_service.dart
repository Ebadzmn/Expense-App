import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:your_expense/services/token_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class ApiBaseService extends GetxService {
  final http.Client _client = http.Client();

  Future<ApiBaseService> init() async {
    if (kDebugMode) {
      debugPrint('✅ ApiBaseService initialized');
    }
    return this;
  }

  Future<dynamic> request(
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        Map<String, dynamic>? queryParams,
        bool requiresAuth = true,
      }) async {
    try {
      final tokenService = Get.isRegistered<TokenService>()
          ? Get.find<TokenService>()
          : null;
      if (kDebugMode) {
        debugPrint('=== 🔐 TOKEN STATUS ===');
        debugPrint('Token exists: ${tokenService?.getToken() != null}');
        debugPrint('Token valid: ${tokenService?.isTokenValid() == true}');
        debugPrint('User ID: ${tokenService?.getUserId()}');
        debugPrint('=======================');
      }

      if (requiresAuth && (tokenService == null || tokenService.isTokenValid() != true)) {
        print('❌ Auth required but token is invalid!');
        throw Exception('Authentication required. Please login again.');
      }

      Uri uri = Uri.parse(endpoint);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) =>
            MapEntry(key, value.toString())));
      }
      if (kDebugMode) {
        debugPrint('=== 🚀 Final API URL ===');
        debugPrint('URL: $uri');
        debugPrint('=== End URL ===');
      }

      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      if (requiresAuth && tokenService != null && tokenService.isTokenValid()) {
        requestHeaders['Authorization'] = 'Bearer ${tokenService.getToken()}';
        if (kDebugMode) debugPrint('🔐 Added auth token to request');
      } else if (requiresAuth) {
        if (kDebugMode) {
          debugPrint('⚠️ Auth required but no valid token found!');
          debugPrint('⚠️ Token exists: ${tokenService?.getToken() != null}');
          debugPrint('⚠️ Token valid: ${tokenService?.isTokenValid() == true}');
        }
      }

      if (kDebugMode) {
        debugPrint('''
=== 🚀 API Request Details ===
Service: $runtimeType
Method: $method
URL: $uri
Headers: ${requestHeaders.keys.toList()}
Authorization header: ${requestHeaders['Authorization'] ?? 'None'}
Body: ${body != null ? json.encode(body) : 'None'}
Requires Auth: $requiresAuth
Token Valid: ${tokenService?.isTokenValid() == true}
User ID: ${tokenService?.getUserId()}
=== End Details ===
''');
      }

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (kDebugMode) {
        debugPrint('=== 📤 Raw Response ===');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Headers: ${response.headers}');
        debugPrint('Body Preview: ${_truncateString(response.body, 500)}');
        debugPrint('=======================');
      }

      _logResponse(method, endpoint, response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          print('📝 Empty response body - returning empty map');
          return <String, dynamic>{};
        }

        try {
          final decodedResponse = json.decode(response.body);
          print('✅ Successfully decoded response: ${decodedResponse.runtimeType}');
          return decodedResponse;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Failed to decode JSON response: $e');
            debugPrint('📝 Raw response body: ${response.body}');
          }
          throw Exception('Invalid JSON response from server');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ HTTP Error - Status: ${response.statusCode}');
          debugPrint('❌ Error Response: ${response.body}');
        }

        if (response.statusCode == 401) {
          print('🔐 Unauthorized - Token might be invalid or expired');
          // Do NOT clear token automatically; surface error and let UI handle re-login
          throw Exception('Unauthorized. Please login if your session expired.');
        }

        throw HttpException(response.statusCode, response.body);
      }
    } catch (e) {
      _logError(method, endpoint, e);
      rethrow;
    }
  }

  /// Binary request helper for downloading files (PDF/CSV/Excel, etc.).
  /// Returns raw `Uint8List` bytes without attempting JSON decoding.
  Future<Uint8List> requestBytes(
      String method,
      String endpoint, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParams,
        bool requiresAuth = true,
      }) async {
    try {
      final tokenService = Get.isRegistered<TokenService>()
          ? Get.find<TokenService>()
          : null;
      if (kDebugMode) {
        debugPrint('=== 🔐 TOKEN STATUS (bytes) ===');
        debugPrint('Token exists: ${tokenService?.getToken() != null}');
        debugPrint('Token valid: ${tokenService?.isTokenValid() == true}');
        debugPrint('User ID: ${tokenService?.getUserId()}');
        debugPrint('==============================');
      }

      if (requiresAuth && (tokenService == null || tokenService.isTokenValid() != true)) {
        print('❌ Auth required but token is invalid!');
        throw Exception('Authentication required. Please login again.');
      }

      Uri uri = Uri.parse(endpoint);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) =>
            MapEntry(key, value.toString())));
      }
      if (kDebugMode) {
        debugPrint('=== 🚀 Final API URL (bytes) ===');
        debugPrint('URL: $uri');
        debugPrint('=== End URL ===');
      }

      final requestHeaders = {
        // Prefer binary-friendly accept header set; leave content-type unspecified for GET
        'Accept': 'application/pdf, text/csv, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/octet-stream',
        ...?headers,
      };

      if (requiresAuth && tokenService != null && tokenService.isTokenValid()) {
        requestHeaders['Authorization'] = 'Bearer ${tokenService.getToken()}';
        if (kDebugMode) debugPrint('🔐 Added auth token to bytes request');
      }

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method for bytes: $method');
      }

      if (kDebugMode) {
        debugPrint('=== 📤 Raw Bytes Response ===');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Headers: ${response.headers}');
        debugPrint('Content-Type: ${response.headers['content-type']}');
        debugPrint('Content-Length: ${response.headers['content-length'] ?? response.bodyBytes.length}');
        debugPrint('============================');
      }

      _logResponse(method, endpoint, response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          throw Exception('Empty file response');
        }
        return bytes;
      } else {
        print('❌ HTTP Error - Status: ${response.statusCode}');
        if (response.statusCode == 401) {
          throw Exception('Unauthorized. Please login if your session expired.');
        }
        throw HttpException(response.statusCode, response.body);
      }
    } catch (e) {
      _logError(method, endpoint, e);
      rethrow;
    }
  }

  void _logResponse(String method, String endpoint, http.Response response) {
      if (kDebugMode) {
        debugPrint('''
=== 📨 API Response ===
Service: $runtimeType
Method: $method
URL: $endpoint
Status: ${response.statusCode} ${_getStatusMessage(response.statusCode)}
Content-Type: ${response.headers['content-type'] ?? 'Unknown'}
Content-Length: ${response.headers['content-length'] ?? response.body.length}
Response Preview: ${_truncateString(response.body, 200)}
Response Headers: ${response.headers.keys.toList()}
=== End Response ===
''');
      }
  }

  String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 500: return 'Internal Server Error';
      default: return 'Unknown';
    }
  }

  String _truncateString(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}... [truncated]';
  }

  void _logError(String method, String endpoint, dynamic error) {
    if (kDebugMode) {
      debugPrint('''
!!! 💥 API Error !!!
Service: $runtimeType
Method: $method
URL: $endpoint
Error: $error
Error Type: ${error.runtimeType}
Stack Trace: ${StackTrace.current}
!!! End Error !!!
''');
    }

    if (error is http.ClientException) {
      if (kDebugMode) {
        debugPrint('🌐 Client Exception Details: ${error.message}');
        debugPrint('🔗 URI: ${error.uri}');
      }
    }

    if (error is HttpException) {
      if (kDebugMode) {
        debugPrint('📊 HTTP Status: ${error.statusCode}');
        debugPrint('💬 HTTP Message: ${error.message}');
      }
      try {
        final decodedError = json.decode(error.message);
        if (kDebugMode) debugPrint('🔍 Decoded Error Response: $decodedError');
      } catch (_) {
        if (kDebugMode) debugPrint('📝 Raw Error Body: ${error.message}');
      }
    }
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}

class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException(this.statusCode, this.message);

  @override
  String toString() => 'HTTP $statusCode: $message';
}