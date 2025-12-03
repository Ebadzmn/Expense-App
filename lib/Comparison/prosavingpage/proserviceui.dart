import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Settings/appearance/ThemeController.dart';
import 'prosavings_controller.dart';

class ProSavingsPage extends StatelessWidget {
  const ProSavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final bool isDarkMode = themeController.isDarkModeActive;

    final ProSavingsController controller = Get.put(ProSavingsController());

    return WillPopScope(
      onWillPop: () async {
        Get.back();
        return false;
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios,
                color: isDarkMode ? Colors.white : Colors.black,
                size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'totalSavings'.tr,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.error.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      controller.error.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => controller.fetchSavings(),
                      child: Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }

          if (controller.savings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No savings found. Try adding a comparison.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'totalSaving'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Obx(() => Text(
                                '\$${controller.totalSavings.value.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              )),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode ? const Color(0xFF333333) : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'monthly'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down,
                                size: 16,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Chart Section (dynamic)
                Obx(() => Container(
                      height: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildGraph(isDarkMode, controller),
                    )),

                // Products names row (under the graph)
                Obx(() {
                  final items = controller.graphItems;
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: items.map((m) {
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDarkMode ? const Color(0xFF333333) : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  (m['label'] as String),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Legend
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildLegend(isDarkMode),
                ),

                // Summary Section (dynamic totals)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(() => Column(
                        children: [
                          _buildSummaryRow('withoutAppsTotal'.tr, '\$${controller.totalInitial.value.toStringAsFixed(2)}',
                              isDarkMode ? Colors.white : Colors.black, isDarkMode),
                          const SizedBox(height: 8),
                          _buildSummaryRow('withAppsTotal'.tr, '\$${controller.totalActual.value.toStringAsFixed(2)}',
                              isDarkMode ? Colors.white : Colors.black, isDarkMode),
                          const SizedBox(height: 8),
                          _buildSummaryRow('totalSavingAmount'.tr, '\$${controller.totalSavings.value.toStringAsFixed(2)}',
                              const Color(0xFF88C999), isDarkMode),
                          const SizedBox(height: 8),
                          Builder(builder: (_) {
                            final init = controller.totalInitial.value;
                            final sav = controller.totalSavings.value;
                            final pct = init > 0 ? (sav / init * 100) : 0.0;
                            return Text(
                              'save_percent'.trParams({'percent': pct.toStringAsFixed(0)}),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF88C999),
                              ),
                            );
                          }),
                        ],
                      )),
                ),

                const SizedBox(height: 24),

                // Recent Transactions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'recentTransaction'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Obx(() => ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.recentPurchases.length,
                      itemBuilder: (context, index) {
                        final item = controller.recentPurchases[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDarkMode ? const Color(0xFF333333) : Colors.grey[200]!,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Image.asset(
                                    item['iconAsset'],
                                    color: item['iconColor'],
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.shopping_bag, color: item['iconColor'], size: 18);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Transaction Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['title'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '\$${(item['actual'] as double).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['date'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '\$${(item['initial'] as double).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
                const SizedBox(height: 20),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGraph(bool isDarkMode, ProSavingsController controller) {
    // Always show grouped category bars, scaled by a global max
    final values = controller.topCategories
        .expand((cat) => [
              (cat['initial'] as double),
              (cat['actual'] as double),
              (cat['savings'] as double),
            ])
        .toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Y-axis labels and bars
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis labels
                SizedBox(
                  width: 25,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _scaleLabels(values, isDarkMode),
                  ),
                ),
                const SizedBox(width: 8),
                // Chart bars
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: controller.topCategories.map((cat) {
                      return _buildBarGroup(
                        cat['category'] as String,
                        (cat['initial'] as double),
                        (cat['actual'] as double),
                        (cat['savings'] as double),
                        maxVal,
                        isDarkMode,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarGroup(String label, double original, double usingApp, double savings, double maxV, bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 110,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 6,
                height: _barHeightScaled(original, maxV),
                decoration: BoxDecoration(
                  color: const Color(0xFFA3A3A3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 6,
                height: _barHeightScaled(usingApp, maxV),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 6,
                height: _barHeightScaled(savings, maxV),
                decoration: BoxDecoration(
                  color: const Color(0xFF88C999),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(const Color(0xFFA3A3A3), 'originalPrice'.tr, isDarkMode),
        const SizedBox(width: 12),
        _legendItem(const Color(0xFF4A90E2), 'usingApp'.tr, isDarkMode),
        const SizedBox(width: 12),
        _legendItem(const Color(0xFF88C999), 'saving'.tr, isDarkMode),
      ],
    );
  }

  Widget _legendItem(Color color, String label, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // Helpers for dynamic scale (use a global max)
  double _barHeightScaled(double value, double maxValue) {
    if (maxValue <= 0) return 2.0;
    final normalized = (value / maxValue).clamp(0.0, 1.0);
    final h = 110.0 * normalized;
    return h < 2.0 ? 2.0 : h;
  }

  List<Widget> _scaleLabels(List<double> values, bool isDarkMode) {
    final maxV = values.isEmpty ? 100.0 : values.reduce((a, b) => a > b ? a : b);
    final steps = [maxV, maxV * 0.8, maxV * 0.6, maxV * 0.4, maxV * 0.2, 0.0];
    return steps
        .map((v) => Text(
              v == 0.0 ? '0' : v.toStringAsFixed(0),
              style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ))
        .toList();
  }
}