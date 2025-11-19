import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:intl/intl.dart';
import 'package:your_expense/services/category_service.dart';

import 'expense_model.dart';

class ExpenseService extends GetxService {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _configService = Get.find();
  CategoryService? _categoryService;

  // Static mapping for raw-code categories → backend IDs
  // NOTE: Fill in/adjust IDs to match your backend. These are examples.
  static const Map<String, String> _STATIC_CATEGORY_ID = {
    'food': '68acfc0fffc1998f8c72d9c1',
    'transport': '68ae33e85f040e977f3493e6',
    'groceries': '688e6e829f6edd994b7ea702',
    'eating out': '68acfc0fffc1998f8c72d9c1',
    // 'home': '<PUT_HOME_ID_HERE>',
    // 'other': '<PUT_OTHER_ID_HERE>',
  };

  Future<ExpenseService> init() async {
    print('ExpenseService initialized');
    // Try to bind CategoryService if available
    if (Get.isRegistered<CategoryService>()) {
      _categoryService = Get.find<CategoryService>();
      // Debug: print accessible categories to help fill static map
      try {
        final cats = await _categoryService!.fetchExpenseCategories();
        print('📚 Accessible categories (name -> id):');
        for (final c in cats) {
          print(' - ${c.name} -> ${c.id}');
        }
      } catch (e) {
        print('⚠️ Could not fetch categories in init: $e');
      }
    }
    return this;
  }

  Future<List<ExpenseItem>> getExpenses() async {
    try {
      print('🔍 Fetching expenses from: ${_configService.expenseEndpoint}');

      final response = await _apiService.request(
        'GET',
        _configService.expenseEndpoint,
        requiresAuth: true,
      );

      // Debug the response
      print('📋 API Response type: ${response.runtimeType}');
      print('📋 API Response: $response');

      // Check if response is null or empty
      if (response == null) {
        print('❌ Response is null');
        throw Exception('No response received from server');
      }

      // Based on your JSON example, the API returns the array directly
      if (response is List) {
        print('✅ Successfully received list of ${response.length} expenses');

        List<ExpenseItem> expensesList = [];

        for (int i = 0; i < response.length; i++) {
          try {
            final item = response[i];
            print('🔄 Processing item $i: $item');

            if (item is Map<String, dynamic>) {
              final expense = ExpenseItem.fromJson(item);
              expensesList.add(expense);
              print('✅ Successfully parsed expense: ${expense.id}');
            } else {
              print('⚠️ Invalid item format at index $i: ${item.runtimeType}');
            }
          } catch (e) {
            print('❌ Error parsing expense at index $i: $e');
            // Continue processing other items instead of failing completely
          }
        }

        print('📊 Total successfully parsed expenses: ${expensesList.length}');
        return expensesList;
      }
      // If it's a map, check if it contains the array under common keys
      else if (response is Map<String, dynamic>) {
        print('🗂️ Response is a map, checking for expense data...');
        print('🔑 Available keys: ${response.keys.toList()}');

        List<dynamic>? expensesData;

        if (response.containsKey('data') && response['data'] is List) {
          print('✅ Found expenses in "data" key');
          expensesData = response['data'] as List<dynamic>;
        } else if (response.containsKey('expenses') && response['expenses'] is List) {
          print('✅ Found expenses in "expenses" key');
          expensesData = response['expenses'] as List<dynamic>;
        } else if (response.containsKey('items') && response['items'] is List) {
          print('✅ Found expenses in "items" key');
          expensesData = response['items'] as List<dynamic>;
        } else {
          print('❌ Could not find expense list in response map. Keys: ${response.keys}');
          throw Exception('No expense data found in response. Response keys: ${response.keys}');
        }

        List<ExpenseItem> expensesList = [];

        for (int i = 0; i < expensesData.length; i++) {
          try {
            final item = expensesData[i];
            if (item is Map<String, dynamic>) {
              final expense = ExpenseItem.fromJson(item);
              expensesList.add(expense);
            }
          } catch (e) {
            print('❌ Error parsing expense at index $i: $e');
          }
        }

        return expensesList;
            }
      else {
        print('❌ Unexpected response type: ${response.runtimeType}');
        print('❌ Response content: $response');
        throw Exception('Invalid response format from expense API. Expected List or Map, got ${response.runtimeType}');
      }

      return [];
    } catch (e) {
      print('💥 Error fetching expenses: $e');
      print('💥 Error type: ${e.runtimeType}');
      print('💥 Stack trace: ${StackTrace.current}');
      // Gracefully handle unauthenticated or network errors by returning an empty list
      return [];
    }
  }

  Future<ExpenseItem> createExpense({
    required double amount,
    required String category,
    String note = '',
    DateTime? date,
    String? month,
  }) async {
    try {
      print('➕ Creating new expense: amount=$amount, category=$category, note=$note');

      final effectiveDate = date ?? DateTime.now();
      final monthStr = DateFormat('yyyy-MM').format(effectiveDate);
      final isoDate = effectiveDate.toIso8601String();
      final Map<String, dynamic> body = {
        // Send both keys to match varying backend expectations
        'source': category,
        'category': category,
        'categoryName': category,
        'amount': amount,
        'note': note,
        // Always include explicit date fields
        'date': isoDate,
        'createdAt': isoDate,
        // Always include month derived from date for summary alignment
        'month': (month != null && month.isNotEmpty) ? month : monthStr,
      };
      print('📦 Sending payload (create): $body');

      Map<String, dynamic> data;
      try {
        final response = await _apiService.request(
          'POST',
          _configService.expenseEndpoint,
          body: body,
          requiresAuth: true,
        );
        print('✅ Create expense response: $response');
        if (response is Map<String, dynamic> && response.containsKey('data')) {
          final d = response['data'];
          data = d is Map<String, dynamic> ? d : <String, dynamic>{};
        } else if (response is Map<String, dynamic>) {
          data = response;
        } else {
          throw Exception('Invalid response format when creating expense');
        }
      } on HttpException catch (he) {
        if (he.statusCode == 400 && (he.message.contains('Validation Error') || he.message.contains('Required') || he.message.contains('source'))) {
          print('🔁 ${he.statusCode} "${he.message}" → enforcing source/month/date then retry');
          final effectiveDate = date ?? DateTime.now();
          final monthStr = DateFormat('yyyy-MM').format(effectiveDate);
          final isoDate = effectiveDate.toIso8601String();
          final retryBody = {
            'source': category,
            'category': category,
            'categoryName': category,
            'amount': amount,
            'note': note,
            'date': isoDate,
            'createdAt': isoDate,
            'month': (month != null && month.isNotEmpty) ? month : monthStr,
          };
          final retryResp = await _apiService.request(
            'POST',
            _configService.expenseEndpoint,
            body: retryBody,
            requiresAuth: true,
          );
          print('✅ Retry create response: $retryResp');
          if (retryResp is Map<String, dynamic> && retryResp.containsKey('data')) {
            final d = retryResp['data'];
            data = d is Map<String, dynamic> ? d : <String, dynamic>{};
          } else if (retryResp is Map<String, dynamic>) {
            data = retryResp;
          } else {
            throw Exception('Invalid response format on retry when creating expense');
          }
        } else {
          rethrow;
        }
      }

      return ExpenseItem.fromJson(data);
    } catch (e) {
      print('❌ Error creating expense: $e');
      rethrow;
    }
  }

  Future<ExpenseItem> updateExpense({
    required String id,
    double? amount,
    String? category,
    String? note,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (amount != null) body['amount'] = amount;
      if (category != null) {
        // update with all known keys for compatibility
        body['source'] = category;
        body['category'] = category;
        body['categoryName'] = category;
      }
      if (note != null) body['note'] = note;

      print('📦 Sending payload (update): $body');

      try {
        final response = await _apiService.request(
          'PUT',
          '${_configService.expenseEndpoint}/$id',
          body: body,
          requiresAuth: true,
        );
        if (response is Map<String, dynamic>) {
          final data = response['data'] is Map<String, dynamic>
              ? response['data'] as Map<String, dynamic>
              : response;
          return ExpenseItem.fromJson(data);
        } else {
          throw Exception('Invalid response format on update');
        }
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      print('❌ Error updating expense: $e');
      rethrow;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      final response = await _apiService.request(
        'DELETE',
        '${_configService.expenseEndpoint}/$id',
        requiresAuth: true,
      );
      if (response is Map<String, dynamic>) {
        if (response['success'] == true) return true;
      }
      // Some backends return 200 with empty body
      return true;
    } catch (e) {
      print('❌ Error deleting expense: $e');
      return false;
    }
  }
}

// Top-level stubs to satisfy helper references (not used in runtime)
final ApiBaseService _apiService = Get.find<ApiBaseService>();
final ConfigService _configService = Get.find<ConfigService>();
CategoryService? _categoryService = Get.isRegistered<CategoryService>() ? Get.find<CategoryService>() : null;
const Map<String, String> _STATIC_CATEGORY_ID = {};

bool _isValidObjectId(String s) {
  return s.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(s);
}

// Normalize a category name into tokens (lowercase, alphanumeric words)
Set<String> _tokens(String s) {
  final normalized = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  final parts = normalized.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toSet();
  return _expandSynonyms(parts);
}

// Minimal synonyms expansion to improve matching
Set<String> _expandSynonyms(Set<String> tokens) {
  final Set<String> out = {...tokens};
  for (final t in tokens) {
    switch (t) {
      case 'food':
      case 'groceries':
      case 'dining':
      case 'restaurant':
      case 'eat':
      case 'eating':
      case 'meal':
        out.addAll({'food', 'groceries', 'dining', 'restaurant'});
        break;
      case 'transport':
      case 'transportation':
      case 'commute':
      case 'car':
      case 'bus':
        out.addAll({'transport', 'transportation'});
        break;
      case 'home':
      case 'housing':
      case 'utilities':
      case 'rent':
        out.addAll({'home', 'housing', 'utilities'});
        break;
      case 'other':
      case 'misc':
      case 'miscellaneous':
        out.addAll({'other', 'misc', 'miscellaneous'});
        break;
    }
  }
  return out;
}

String? _findBestCategoryIdByTokens(List<ExpenseCategory> cats, String name) {
  final target = _tokens(name);
  int bestScore = 0;
  String? bestId;
  for (final c in cats) {
    final ct = _tokens(c.name);
    final score = ct.intersection(target).length;
    if (score > bestScore) {
      bestScore = score;
      bestId = c.id;
    } else if (score == 0) {
      // Fallback contains check
      final a = c.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
      final b = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
      if (a.contains(b) || b.contains(a)) {
        bestScore = 1; // minimal match
        bestId = c.id;
      }
    }
    return bestScore > 0 ? bestId : null;
  }

  // Helper: resolve frontend category name to backend category ID
  Future<String?> _resolveCategoryId(String name) async {
    try {
      final lower = name.toLowerCase();

      // 1) Prefer CategoryService if registered (use accessible categories)
      if (Get.isRegistered<CategoryService>()) {
        final service = _categoryService ?? Get.find<CategoryService>();
        final cats = await service.fetchExpenseCategories();
        final exact = cats.firstWhere(
          (c) => c.name.toLowerCase() == lower,
          orElse: () => ExpenseCategory(id: '', name: ''),
        );
      if (exact.id.isNotEmpty) {
        return exact.id;
      }
      final fuzzyId = _findBestCategoryIdByTokens(cats, name);
      if (fuzzyId != null && _isValidObjectId(fuzzyId)) {
        return fuzzyId;
      }
      }

      // Fallback: API call
      final response = await _apiService.request(
        'GET',
        _configService.categoryEndpoint,
        requiresAuth: true,
      );
      List<dynamic> items = [];
      if (response is List) {
        items = response;
      } else if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          items = data;
        } else if (response['categories'] is List) {
          items = response['categories'];
        } else if (response['items'] is List) {
          items = response['items'];
        }
      }
      final cats = items
          .whereType<Map<String, dynamic>>()
          .map((e) => ExpenseCategory.fromJson(e))
          .where((c) => c.name.isNotEmpty)
          .toList();
      final exact2 = cats.firstWhere(
        (c) => c.name.toLowerCase() == lower,
        orElse: () => ExpenseCategory(id: '', name: ''),
      );
      if (exact2.id.isNotEmpty) {
        return exact2.id;
      }
      final fuzzyId2 = _findBestCategoryIdByTokens(cats, name);
      if (fuzzyId2 != null && _isValidObjectId(fuzzyId2)) {
        return fuzzyId2;
      }

      return null;
    } catch (e) {
      print('⚠️ Category lookup failed: $e');
      // On lookup failure, try static ID as last resort
      final lower = name.toLowerCase();
      final staticId = _STATIC_CATEGORY_ID[lower];
      if (staticId != null && _isValidObjectId(staticId)) {
        print('📎 Lookup failed; using static ID $staticId (may not be accessible)');
        return staticId;
      }
      return null;
    }
  }

  // Removed duplicate _isValidObjectId definition to prevent shadowing issues
  // (removed) duplicate _isValidObjectId definition; using earlier helper

  // Strict resolver: only uses accessible categories (CategoryService/API), never static map
  Future<String?> _resolveCategoryIdStrict(String name) async {
    try {
      final lower = name.toLowerCase();
      // Prefer CategoryService
      if (Get.isRegistered<CategoryService>()) {
        final service = _categoryService ?? Get.find<CategoryService>();
        final cats = await service.fetchExpenseCategories();
        final exact = cats.firstWhere(
          (c) => c.name.toLowerCase() == lower,
          orElse: () => ExpenseCategory(id: '', name: ''),
        );
        if (exact.id.isNotEmpty) return exact.id;
        final fuzzyId = _findBestCategoryIdByTokens(cats, name);
        if (fuzzyId != null && _isValidObjectId(fuzzyId)) {
          return fuzzyId;
        }
      }

      // Fallback: API call
      final response = await _apiService.request(
        'GET',
        _configService.categoryEndpoint,
        requiresAuth: true,
      );
      List<dynamic> items = [];
      if (response is List) {
        items = response;
      } else if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          items = data;
        } else if (response['categories'] is List) {
          items = response['categories'];
        } else if (response['items'] is List) {
          items = response['items'];
        }
      }
      final cats = items
          .whereType<Map<String, dynamic>>()
          .map((e) => ExpenseCategory.fromJson(e))
          .where((c) => c.name.isNotEmpty)
          .toList();
      final exact2 = cats.firstWhere(
        (c) => c.name.toLowerCase() == lower,
        orElse: () => ExpenseCategory(id: '', name: ''),
      );
      if (exact2.id.isNotEmpty) {
        return exact2.id;
      }
      final fuzzyId2 = _findBestCategoryIdByTokens(cats, name);
      if (fuzzyId2 != null && _isValidObjectId(fuzzyId2)) {
        return fuzzyId2;
      }

      return null;
    } catch (e) {
      print('⚠️ Strict category lookup failed: $e');
      return null;
    }
  }
}