import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

class ProSavingsController extends GetxController {
  final ApiBaseService _api = Get.find();
  final ConfigService _config = Get.find();

  // Core data
  final RxList<dynamic> savings = <dynamic>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  // Totals for summary
  final RxDouble totalInitial = 0.0.obs;
  final RxDouble totalActual = 0.0.obs;
  final RxDouble totalSavings = 0.0.obs;

  // Graph data: top categories by savings
  final RxList<Map<String, dynamic>> topCategories = <Map<String, dynamic>>[].obs;

  // Graph data: per-product items (recent N items)
  final RxList<Map<String, dynamic>> graphItems = <Map<String, dynamic>>[].obs;

  // Selected product index for graph filtering (-1 means none selected)
  final RxInt selectedGraphIndex = (-1).obs;

  // Recent purchases (mapped for UI)
  final RxList<Map<String, dynamic>> recentPurchases = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSavings();
  }

  Future<void> fetchSavings() async {
    try {
      isLoading.value = true;
      error.value = '';

      final res = await _api.request('GET', _config.savingsEndpoint, requiresAuth: true);
      if (res['success'] != true) {
        throw Exception('Request failed');
      }

      final List<dynamic> data = (res['data'] ?? []) as List<dynamic>;
      savings.assignAll(data);

      _computeTotals(data);
      _computeTopCategories(data);
      _computeRecentPurchases(data);
      _computeGraphItems(data);
    } catch (e) {
      error.value = 'Failed to load savings: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void _computeTotals(List<dynamic> data) {
    double initial = 0.0;
    double actual = 0.0;
    double saving = 0.0;

    for (final item in data) {
      initial += (item['initialPrice'] ?? 0).toDouble();
      actual += (item['actualPrice'] ?? 0).toDouble();
      saving += (item['savings'] ?? ((item['initialPrice'] ?? 0) - (item['actualPrice'] ?? 0))).toDouble();
    }

    totalInitial.value = initial;
    totalActual.value = actual;
    totalSavings.value = saving;
  }

  void _computeTopCategories(List<dynamic> data) {
    final Map<String, Map<String, double>> agg = {};
    for (final item in data) {
      final String cat = (item['category'] ?? 'Unknown').toString();
      final double init = (item['initialPrice'] ?? 0).toDouble();
      final double act = (item['actualPrice'] ?? 0).toDouble();
      final double sav = (item['savings'] ?? (init - act)).toDouble();

      agg.putIfAbsent(cat, () => {'initial': 0.0, 'actual': 0.0, 'savings': 0.0});
      agg[cat]!['initial'] = (agg[cat]!['initial'] ?? 0) + init;
      agg[cat]!['actual'] = (agg[cat]!['actual'] ?? 0) + act;
      agg[cat]!['savings'] = (agg[cat]!['savings'] ?? 0) + sav;
    }

    final List<Map<String, dynamic>> list = agg.entries
        .map((e) => {
              'category': e.key,
              'initial': e.value['initial'] ?? 0.0,
              'actual': e.value['actual'] ?? 0.0,
              'savings': e.value['savings'] ?? 0.0,
            })
        .toList();

    list.sort((a, b) => (b['savings'] as double).compareTo(a['savings'] as double));
    topCategories.assignAll(list.take(5));
  }

  void _computeRecentPurchases(List<dynamic> data) {
    final mapped = data.take(4).map((item) {
      final String category = (item['category'] ?? 'Unknown').toString();
      final double actual = (item['actualPrice'] ?? 0).toDouble();
      final double initial = (item['initialPrice'] ?? 0).toDouble();
      final String date = (item['createdAt'] ?? '').toString();

      return {
        'title': category,
        'actual': actual,
        'initial': initial,
        'date': _formatDate(date),
        // Lightweight icon/color mapping; UI falls back if asset missing
        'iconAsset': _iconFor(category)['icon'],
        'iconColor': _iconFor(category)['color'],
      };
    }).toList();

    recentPurchases.assignAll(mapped);
  }

  void _computeGraphItems(List<dynamic> data) {
    // Sort by createdAt desc if available
    final sorted = [...data];
    sorted.sort((a, b) {
      final ad = (a['createdAt'] ?? '') as String;
      final bd = (b['createdAt'] ?? '') as String;
      DateTime? adt;
      DateTime? bdt;
      try {
        adt = ad.isNotEmpty ? DateTime.parse(ad) : null;
      } catch (_) {}
      try {
        bdt = bd.isNotEmpty ? DateTime.parse(bd) : null;
      } catch (_) {}
      if (adt == null && bdt == null) return 0;
      if (adt == null) return 1;
      if (bdt == null) return -1;
      return bdt.compareTo(adt);
    });

    final items = sorted.map((item) {
      final String label = (item['category'] ?? 'Item').toString();
      final double init = (item['initialPrice'] ?? 0).toDouble();
      final double act = (item['actualPrice'] ?? 0).toDouble();
      final double sav = (item['savings'] ?? (init - act)).toDouble();
      return {
        'label': label,
        'initial': init,
        'actual': act,
        'savings': sav,
      };
    }).toList();

    graphItems.assignAll(items);

    // Reset selection if out of range; default to first item if available
    if (graphItems.isEmpty) {
      selectedGraphIndex.value = -1;
    } else if (selectedGraphIndex.value < 0 || selectedGraphIndex.value >= graphItems.length) {
      selectedGraphIndex.value = 0;
    }
  }

  Map<String, dynamic> _iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('electronics') || c.contains('bluetooth')) {
      return {'icon': 'assets/icons/Group 12 (1).png', 'color': Colors.blue};
    }
    if (c.contains('laptop') || c.contains('computer')) {
      return {'icon': 'assets/icons/laptop_icon.png', 'color': Colors.purple};
    }
    if (c.contains('phone') || c.contains('mobile')) {
      return {'icon': 'assets/icons/phone_icon.png', 'color': Colors.green};
    }
    if (c.contains('shoe') || c.contains('fashion')) {
      return {'icon': 'assets/icons/shoe_icon.png', 'color': Colors.red};
    }
    if (c.contains('grocery') || c.contains('food')) {
      return {'icon': 'assets/icons/grocery_icon.png', 'color': Colors.amber};
    }
    return {'icon': 'assets/icons/Group 23.png', 'color': Colors.grey};
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return '';
      final dt = DateTime.parse(dateString);
      final two = (int n) => n.toString().padLeft(2, '0');
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '${two(dt.month)}/${two(dt.day)}/${dt.year.toString().substring(2)}, ${hour}:${two(dt.minute)} $period';
    } catch (_) {
      return '';
    }
  }
}