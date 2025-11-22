import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../routes/app_routes.dart';
import '../../services/config_service.dart';
import '../../services/token_service.dart';

class ProfileService extends GetxService {
  static ProfileService get to {
    if (Get.isRegistered<ProfileService>()) {
      return Get.find<ProfileService>();
    }
    return Get.put(ProfileService());
  }
  final ConfigService configService = ConfigService.to;
  final TokenService tokenService = TokenService.to;
  final RxString userName = 'John Doe'.obs;
  final RxString profileImage = ''.obs;
  final RxString email = ''.obs;
  final RxInt imageVersion = 0.obs; // Add version counter for cache busting
  final RxString lastErrorMessage = ''.obs;

  Future<ProfileService> init() async {
    try {
      await fetchUserProfile();
      print('✅ ProfileService initialized');
      return this;
    } catch (e) {
      print('❌ ProfileService initialization failed: $e');
      rethrow;
    }
  }

  Future<void> fetchUserProfile({bool forceRefresh = false}) async {
    try {
      print('🚀 Starting profile fetch (forceRefresh: $forceRefresh)...');
      final token = tokenService.getToken();
      if (token == null) {
        print('❌ No token available for profile fetch');
        return;
      }
      if (!tokenService.isTokenValid()) {
        print('❌ Token is invalid or expired');
        Get.toNamed(AppRoutes.login);
        return;
      }

      print('📡 Sending GET request to: ${configService.userProfileEndpoint}');

      if (forceRefresh) {
        // Clear both image cache and evict specific image
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        imageVersion.value++; // Increment version for cache busting
        print('🧹 Image cache cleared, version: ${imageVersion.value}');
      }

      final response = await http.get(
        Uri.parse(configService.userProfileEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache', // Prevent HTTP caching
        },
      ).timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('📋 HTTP Status: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('📋 Parsed JSON: $jsonResponse');

        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          userName.value = data['name'] ?? 'John Doe';
          email.value = data['email'] ?? '';

          // Handle image URL - check if it's absolute or relative
          String imageUrl = data['image'] ?? '';
          if (imageUrl.isNotEmpty) {
            // If the URL already contains http/https, use it as is
            if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
              profileImage.value = imageUrl;
            } else {
              // Otherwise, it's a relative path
              profileImage.value = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
            }
          } else {
            profileImage.value = '';
          }

          print('✅ Fetched Name: ${userName.value}');
          print('✅ Fetched Email: ${email.value}');
          print('✅ Fetched Image URL: ${profileImage.value}');
        } else {
          print('❌ Profile fetch failed: ${jsonResponse['message']}');
        }
      } else {
        print('❌ Profile fetch HTTP error: ${response.statusCode} - ${response.reasonPhrase}');
        if (response.statusCode == 401) {
          Get.toNamed(AppRoutes.login);
        }
      }
    } catch (e) {
      print('❌ Profile fetch error: $e');
    }
  }

  Future<bool> updateProfile({String? name, XFile? imageFile}) async {
    try {
      final token = tokenService.getToken();
      if (token == null || !tokenService.isTokenValid()) {
        print('❌ No valid token for profile update');
        Get.toNamed(AppRoutes.login);
        return false;
      }

      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse(configService.userProfileEndpoint),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
        print('📋 Adding name to request: $name');
      }

      if (imageFile != null) {
        // Read file bytes
        final bytes = await imageFile.readAsBytes();
        print('📋 Image file size: ${bytes.length} bytes');

        // Determine MIME type
        String mimeType = imageFile.mimeType ?? 'image/jpeg';
        List<String> mimeTypeParts = mimeType.split('/');
        String type = mimeTypeParts[0];
        String subtype = mimeTypeParts.length > 1 ? mimeTypeParts[1] : 'jpeg';

        print('📋 Image MIME type: $mimeType');

        // Add file to request
        request.files.add(
          http.MultipartFile.fromBytes(
            'image', // Make sure this matches your backend field name
            bytes,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.$subtype',
            contentType: MediaType(type, subtype),
          ),
        );
        print('📋 Adding image to request: ${imageFile.path}');
      }

      print('📡 Sending PATCH request to: ${configService.userProfileEndpoint}');
      print('📋 Request headers: ${request.headers}');
      print('📋 Request fields: ${request.fields}');

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = response.body;

      print('📋 Update HTTP Status: ${response.statusCode}');
      print('📋 Update Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = json.decode(responseBody);
          if (jsonResponse['success'] == true) {
            print('✅ Profile updated successfully');

            // Immediately update local state from the response data
            final data = jsonResponse['data'];
            userName.value = data['name'] ?? 'John Doe';
            email.value = data['email'] ?? '';

            // Handle image URL - check if it's absolute or relative
            String imageUrl = data['image'] ?? '';
            if (imageUrl.isNotEmpty) {
              if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
                profileImage.value = imageUrl;
              } else {
                profileImage.value = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
              }
            } else {
              profileImage.value = '';
            }

            print('✅ Updated Name: ${userName.value}');
            print('✅ Updated Email: ${email.value}');
            print('✅ Updated Image URL: ${profileImage.value}');

            // Clear image cache immediately
            PaintingBinding.instance.imageCache.clear();
            PaintingBinding.instance.imageCache.clearLiveImages();
            imageVersion.value++;

            return true;
          } else {
            print('❌ Profile update failed: ${jsonResponse['message']}');
            return false;
          }
        } catch (e) {
          print('❌ JSON parse error: $e');
          print('Response was: $responseBody');
          return false;
        }
      } else {
        print('❌ Profile update HTTP error: ${response.statusCode}');
        print('Response body: $responseBody');

        // Fallback: Some servers don't accept PATCH for multipart. Try PUT.
        if (imageFile != null) {
          try {
            print('⚠️ PATCH failed. Retrying image upload with PUT...');
            var putRequest = http.MultipartRequest(
              'PUT',
              Uri.parse(configService.userProfileEndpoint),
            );
            putRequest.headers['Authorization'] = 'Bearer $token';
            putRequest.headers['Accept'] = 'application/json';

            if (name != null && name.isNotEmpty) {
              putRequest.fields['name'] = name;
            }

            final bytes = await imageFile.readAsBytes();
            String mimeType = imageFile.mimeType ?? 'image/jpeg';
            List<String> mimeTypeParts = mimeType.split('/');
            String type = mimeTypeParts[0];
            String subtype = mimeTypeParts.length > 1 ? mimeTypeParts[1] : 'jpeg';

            putRequest.files.add(
              http.MultipartFile.fromBytes(
                'image',
                bytes,
                filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.$subtype',
                contentType: MediaType(type, subtype),
              ),
            );

            final putStreamedResponse = await putRequest.send().timeout(
              Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Upload timeout');
              },
            );
            final putResponse = await http.Response.fromStream(putStreamedResponse);
            final putBody = putResponse.body;

            print('📋 PUT Update HTTP Status: ${putResponse.statusCode}');
            print('📋 PUT Update Response Body: $putBody');

            if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
              final jsonResponse = json.decode(putBody);
              if (jsonResponse['success'] == true) {
                final data = jsonResponse['data'];
                userName.value = data['name'] ?? 'John Doe';
                email.value = data['email'] ?? '';
                String imageUrl = data['image'] ?? '';
                if (imageUrl.isNotEmpty) {
                  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
                    profileImage.value = imageUrl;
                  } else {
                    profileImage.value = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
                  }
                } else {
                  profileImage.value = '';
                }
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
                imageVersion.value++;
                print('✅ Profile updated successfully via PUT');
                return true;
              } else {
                print('❌ Profile update via PUT failed: ${jsonResponse['message']}');
              }
            } else {
              print('❌ Profile update HTTP error via PUT: ${putResponse.statusCode}');
            }
          } catch (e) {
            print('❌ PUT fallback error: $e');
          }
        }

        return false;
      }
    } catch (e) {
      print('❌ Profile update error: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<void> refreshProfile() async {
    await fetchUserProfile(forceRefresh: true);
  }

  // Helper method to get full image URL
  String getFullImageUrl() {
    if (profileImage.value.isEmpty) return '';

    if (profileImage.value.startsWith('http://') ||
        profileImage.value.startsWith('https://')) {
      return '${profileImage.value}?v=${imageVersion.value}';
    }

    final baseUri = Uri.parse(configService.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    return '$origin${profileImage.value}?v=${imageVersion.value}';
  }

  // New method to send OTP
  Future<bool> sendOtp() async {
    try {
      final response = await http.post(
        Uri.parse('${configService.baseUrl}/user/send-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email.value}),
      );

      print('📋 Send OTP HTTP Status: ${response.statusCode}');
      print('📋 Send OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          print('✅ OTP sent successfully');
          return true;
        } else {
          print('❌ OTP send failed: ${jsonResponse['message']}');
          return false;
        }
      } else {
        print('❌ OTP send HTTP error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ OTP send error: $e');
      return false;
    }
  }

  // New method to update password
  Future<bool> updatePassword(String newPassword, int otp) async {
    try {
      final token = tokenService.getToken();
      if (token == null || !tokenService.isTokenValid()) {
        print('❌ No valid token for password update');
        Get.toNamed(AppRoutes.login);
        return false;
      }

      final response = await http.patch(
        Uri.parse('${configService.baseUrl}/user/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'newPassword': newPassword, 'otp': otp}),
      );

      print('📋 Update Password HTTP Status: ${response.statusCode}');
      print('📋 Update Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          print('✅ Password updated successfully');
          return true;
        } else {
          print('❌ Password update failed: ${jsonResponse['message']}');
          return false;
        }
      } else {
        print('❌ Password update HTTP error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Password update error: $e');
      return false;
    }
  }

  Future<bool> changePasswordWithCurrent({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = tokenService.getToken();
      if (token == null || !tokenService.isTokenValid()) {
        lastErrorMessage.value = 'Session expired';
        Get.toNamed(AppRoutes.login);
        return false;
      }

      final response = await http.post(
        Uri.parse('${configService.changePasswordEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      print('📋 Change Password HTTP Status: ${response.statusCode}');
      print('📋 Change Password Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse is Map) {
            final success = jsonResponse['success'] == true;
            final message = (jsonResponse['message'] ?? '').toString();
            if (success) {
              lastErrorMessage.value = '';
              return true;
            }
            lastErrorMessage.value = message.isNotEmpty ? message : 'Password change failed';
          }
        } catch (e) {
          print('❌ JSON parse error: $e');
          lastErrorMessage.value = 'Unexpected response from server';
        }
        return false;
      } else {
        // Optional fallback if server rejects PATCH
        if (response.statusCode == 405) {
          try {
            final postResp = await http.post(
              Uri.parse('${configService.changePasswordEndpoint}'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: json.encode({
                'currentPassword': currentPassword,
                'newPassword': newPassword,
                'confirmPassword': confirmPassword,
              }),
            );
            print('📋 Fallback POST Status: ${postResp.statusCode}');
            print('📋 Fallback POST Body: ${postResp.body}');
            if (postResp.statusCode == 200 || postResp.statusCode == 201) {
              try {
                final jsonResponse = json.decode(postResp.body);
                if (jsonResponse is Map && jsonResponse['success'] == true) {
                  lastErrorMessage.value = '';
                  return true;
                }
                lastErrorMessage.value = (jsonResponse['message'] ?? 'Password change failed').toString();
              } catch (_) {
                lastErrorMessage.value = 'Unexpected response from server';
              }
              return false;
            }
          } catch (e) {
            print('❌ Fallback POST error: $e');
          }
        }

        // Try to extract message from error body
        String serverMessage = '';
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse is Map) {
            serverMessage = (jsonResponse['message'] ?? '').toString();
          }
        } catch (_) {}
        lastErrorMessage.value = serverMessage.isNotEmpty
            ? serverMessage
            : 'HTTP ${response.statusCode}: Password change failed';
        return false;
      }
    } catch (e) {
      print('❌ Change password error: $e');
      lastErrorMessage.value = 'Network error during password change';
      return false;
    }
  }
}