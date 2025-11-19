import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:your_expense/services/token_service.dart';
import 'dart:convert';

class ApiBaseService extends GetxService {
  final TokenService _tokenService = Get.find();
  final http.Client _client = http.Client();

  Future<ApiBaseService> init() async {
    print('✅ ApiBaseService initialized');
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
      print('=== 🔐 TOKEN STATUS ===');
      print('Token exists: ${_tokenService.getToken() != null}');
      print('Token valid: ${_tokenService.isTokenValid()}');
      print('User ID: ${_tokenService.getUserId()}');
      print('=======================');

      if (requiresAuth && !_tokenService.isTokenValid()) {
        print('❌ Auth required but token is invalid!');
        throw Exception('Authentication required. Please login again.');
      }

      Uri uri = Uri.parse(endpoint);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) =>
            MapEntry(key, value.toString())));
      }
      print('=== 🚀 Final API URL ===');
      print('URL: $uri');
      print('=== End URL ===');

      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };

      if (requiresAuth && _tokenService.isTokenValid()) {
        requestHeaders['Authorization'] = 'Bearer ${_tokenService.getToken()}';
        print('🔐 Added auth token to request');
      } else if (requiresAuth) {
        print('⚠️ Auth required but no valid token found!');
        print('⚠️ Token exists: ${_tokenService.getToken() != null}');
        print('⚠️ Token valid: ${_tokenService.isTokenValid()}');
      }

      print('''
=== 🚀 API Request Details ===
Service: $runtimeType
Method: $method
URL: $uri
Headers: ${requestHeaders.keys.toList()}
Authorization header: ${requestHeaders['Authorization'] ?? 'None'}
Body: ${body != null ? json.encode(body) : 'None'}
Requires Auth: $requiresAuth
Token Valid: ${_tokenService.isTokenValid()}
User ID: ${_tokenService.getUserId()}
=== End Details ===
''');

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

      print('=== 📤 Raw Response ===');
      print('Status: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body Preview: ${_truncateString(response.body, 500)}');
      print('=======================');

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
          print('❌ Failed to decode JSON response: $e');
          print('📝 Raw response body: ${response.body}');
          throw Exception('Invalid JSON response from server');
        }
      } else {
        print('❌ HTTP Error - Status: ${response.statusCode}');
        print('❌ Error Response: ${response.body}');

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

  void _logResponse(String method, String endpoint, http.Response response) {
    print('''
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
    print('''
!!! 💥 API Error !!!
Service: $runtimeType
Method: $method
URL: $endpoint
Error: $error
Error Type: ${error.runtimeType}
Stack Trace: ${StackTrace.current}
!!! End Error !!!
''');

    if (error is http.ClientException) {
      print('🌐 Client Exception Details: ${error.message}');
      print('🔗 URI: ${error.uri}');
    }

    if (error is HttpException) {
      print('📊 HTTP Status: ${error.statusCode}');
      print('💬 HTTP Message: ${error.message}');
      try {
        final decodedError = json.decode(error.message);
        print('🔍 Decoded Error Response: $decodedError');
      } catch (_) {
        print('📝 Raw Error Body: ${error.message}');
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