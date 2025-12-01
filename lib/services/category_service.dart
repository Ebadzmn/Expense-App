import 'package:get/get.dart';
import 'api_base_service.dart';
import 'config_service.dart';
import '../models/category_model.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String? icon;
  final String? description;

  ExpenseCategory({
    required this.id, 
    required this.name,
    this.icon,
    this.description,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    // Handle multiple possible keys from various API shapes
    final id = (json['categoryId'] ?? json['id'] ?? json['_id'] ?? '').toString();
    final name = (json['categoryName'] ?? json['name'] ?? json['category'] ?? '').toString();
    final icon = json['icon']?.toString();
    final description = json['description']?.toString();
    return ExpenseCategory(
      id: id, 
      name: name,
      icon: icon,
      description: description,
    );
  }

  // Get icon from static CategoryModel if not provided by API
  String getIconPath() {
    // If API provides icon, trust it
    if (icon != null && icon!.isNotEmpty) {
      return icon!;
    }

    final n = name.toLowerCase();

    // Synonym-based mapping for common categories
    if (n.contains('home') || n.contains('house') || n.contains('housing') || n.contains('rent') || n.contains('utility')) {
      return 'assets/icons/home.png';
    }
    if (n.contains('grocery') || n.contains('grocer') || n.contains('grochery') || n.contains('supermarket') || n.contains('market')) {
      return 'assets/icons/Groceries.png';
    }
    if (n.contains('food') || n.contains('eat') || n.contains('restaurant') || n.contains('cafe') || n.contains('bar') || n.contains('eating out')) {
      return 'assets/icons/eating_out.png';
    }
    if (n.contains('transport') || n.contains('transportation') || n.contains('car') || n.contains('bus') || n.contains('taxi') || n.contains('uber') || n.contains('fuel')) {
      return 'assets/icons/car.png';
    }
    if (n.contains('shop') || n.contains('shopping') || n.contains('clothes') || n.contains('fashion')) {
      return 'assets/icons/shoping.png';
    }

    // Fallback to exact match in CategoryModel
    final categoryModel = CategoryModel.getCategoryByName(name, 'expense');
    if (categoryModel != null && categoryModel.icon.isNotEmpty) {
      return categoryModel.icon;
    }

    // Default if we can't resolve
    return 'assets/icons/money.png';
  }
}

class CategoryService extends GetxService {
  late final ApiBaseService _api;
  late final ConfigService _config;

  CategoryService() {
    _api = ApiBaseService();
    _config = ConfigService();
  }

  Future<CategoryService> init() async {
    // Prefer registered instances from Get
    try {
      _api = Get.find<ApiBaseService>();
    } catch (_) {}
    try {
      _config = Get.find<ConfigService>();
    } catch (_) {}
    return this;
  }

  Future<List<ExpenseCategory>> fetchExpenseCategories() async {
    final endpoint = _config.categoryEndpoint;

    try {
      final response = await _api.request(
        'GET',
        endpoint,
        requiresAuth: true,
      );

      final data = response;
      List<dynamic> items;

      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('data') && data['data'] is List) {
          items = data['data'];
        } else if (data.containsKey('categories') && data['categories'] is List) {
          items = data['categories'];
        } else if (data.containsKey('items') && data['items'] is List) {
          items = data['items'];
        } else {
          // Fallback to any list-like value
          final firstListEntry = data.values.firstWhere(
            (v) => v is List,
            orElse: () => [],
          );
          items = firstListEntry is List ? firstListEntry : [];
        }
      } else {
        items = [];
      }

      final categories = items.map((item) => ExpenseCategory.fromJson(item as Map<String, dynamic>)).toList();
      return categories;
    } catch (e) {
      print('⚠️ CategoryService.fetchExpenseCategories failed: $e');
      return [];
    }
  }

  // Get categories with icon data for UI
  Future<List<Map<String, dynamic>>> fetchCategoriesWithIcons() async {
    try {
      final categories = await fetchExpenseCategories();
      return categories.map((category) => {
        'id': category.id,
        'name': category.name,
        'iconPath': category.getIconPath(),
        'description': category.description ?? '',
      }).toList();
    } catch (e) {
      // Fallback to static categories if API fails
      return CategoryModel.getExpenseCategories().map((category) => {
        'id': category.name.toLowerCase().replaceAll(' ', '_'),
        'name': category.name,
        'iconPath': category.icon,
        'description': category.description ?? '',
      }).toList();
    }
  }

  // Get static categories for immediate UI display
  static List<Map<String, dynamic>> getStaticCategoriesWithIcons() {
    return CategoryModel.getExpenseCategories().map((category) => {
      'id': category.name.toLowerCase().replaceAll(' ', '_'),
      'name': category.name,
      'iconPath': category.icon,
      'description': category.description ?? '',
    }).toList();
  }
}