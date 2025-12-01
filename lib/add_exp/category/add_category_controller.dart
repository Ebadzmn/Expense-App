import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

class AddCategoryController extends GetxController {
  static AddCategoryController get to => Get.find<AddCategoryController>();

  final ApiBaseService _api = Get.find<ApiBaseService>();
  final ConfigService _config = Get.find<ConfigService>();

  // Form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController iconController = TextEditingController();

  // State
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<Map<String, dynamic>> lastResponse = Rxn<Map<String, dynamic>>();

  @override
  void onClose() {
    nameController.dispose();
    iconController.dispose();
    super.onClose();
  }

  /// Convenience setters (optional use from UI)
  void setName(String value) => nameController.text = value.trim();
  void setIcon(String value) => iconController.text = value.trim();

  /// Submit a new category to backend: POST `${baseUrl}/category`
  /// If [name] or [icon] are not provided, controller's current field values are used.
  /// Returns true on success (HTTP 2xx), otherwise throws and returns false.
  Future<bool> submitCategory({String? name, String? icon}) async {
    final String finalName = (name ?? nameController.text).trim();
    final String finalIcon = (icon ?? iconController.text).trim();

    if (finalName.isEmpty) {
      errorMessage.value = 'Name is required';
      Get.snackbar('Invalid', 'Category name is required', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    // Allow empty icon, but prefer a single emoji or short text
    if (finalIcon.length > 8) {
      // simple guard to avoid very long icons
      Get.snackbar('Warning', 'Icon seems too long; consider using an emoji.', snackPosition: SnackPosition.BOTTOM);
    }

    final Map<String, dynamic> body = {
      'name': finalName,
      'icon': finalIcon,
    };

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final endpoint = _config.categoryEndpoint;
      final resp = await _api.request('POST', endpoint, body: body, requiresAuth: true);
      lastResponse.value = (resp is Map<String, dynamic>) ? resp : {'result': resp};

      Get.snackbar('Success', 'Category created successfully', snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Error', 'Failed to create category: $e', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Direct method to post with a map payload, e.g. {"name":"shoppinggg","icon":"🍔"}
  Future<bool> addCategory(Map<String, dynamic> payload) async {
    final String finalName = (payload['name']?.toString() ?? '').trim();
    final String finalIcon = (payload['icon']?.toString() ?? '').trim();
    return submitCategory(name: finalName, icon: finalIcon);
  }
}