import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Settings/appearance/ThemeController.dart';
import '../../routes/app_routes.dart';
import '../comparisongraphcontroller.dart';
import 'package:your_expense/services/subscription_service.dart';


class ComparisonGraphScreen extends StatelessWidget {
  const ComparisonGraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final themeController = Get.find<ThemeController>();
    final bool isDarkMode = themeController.isDarkModeActive;

    // Initialize the controller
    final ComparisonGraphController controller = Get.put(ComparisonGraphController());

    return Scaffold(
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
        title: Obx(() => Text(
          controller.isSpecificComparison.value
              ? '${controller.productCategory.value} Savings'
              : 'compareAndSave'.tr,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        )),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading savings data...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading savings data',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => controller.fetchSavingsData(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.03),

              // Graph Section
              Container(
                width: double.infinity,
                height: screenHeight * 0.3,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF333333) : Colors.grey[200]!,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Graph Title
                      Obx(() => Text(
                        controller.isSpecificComparison.value
                            ? 'Your Savings Comparison'
                            : 'Overall Savings Trend',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      )),
                      SizedBox(height: 10),

                      // Graph Area
                      Expanded(
                        child: CustomPaint(
                          size: const Size(double.infinity, double.infinity),
                          painter: BarChartPainter(
                            isDarkMode: isDarkMode,
                            originalPrice: controller.originalPrice.value,
                            withToolPrice: controller.withToolPrice.value,
                            savingsAmount: controller.savingsAmount.value,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem('Original', Colors.grey, isDarkMode),
                          _buildLegendItem('With Tool', Colors.blue, isDarkMode),
                          _buildLegendItem('Savings', Colors.green, isDarkMode),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // Savings Summary Card
              Obx(() => Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF333333) : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isSpecificComparison.value
                            ? 'Savings Summary'
                            : 'Latest Savings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Original Price',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              Text(
                                '\$${controller.originalPrice.value.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'With Tool',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              Text(
                                '\$${controller.withToolPrice.value.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You Saved',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              Text(
                                '\$${controller.savingsAmount.value.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (controller.originalPrice.value > 0)
                        Text(
                          'Savings: ${((controller.savingsAmount.value / controller.originalPrice.value) * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600],
                          ),
                        ),
                    ],
                  ),
                ),
              )),

              SizedBox(height: screenHeight * 0.03),

              // Purchase Now Button (only show for specific comparisons)
              Obx(() => controller.isSpecificComparison.value ? SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final sub = Get.find<SubscriptionService>();
                    if (sub.isActivePro) {
                      Get.toNamed(AppRoutes.proSavings);
                    } else {
                      Get.toNamed(AppRoutes.nonProSavings);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    'viewAllPurchase'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ) : SizedBox()),

              SizedBox(height: screenHeight * 0.04),

              // Recent Purchase Section
              Text(
                'recentPurchase'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Recent Purchase Items from API (limited to 3)
              if (controller.recentPurchases.isNotEmpty) ...[
                ...controller.recentPurchases.take(3).map((purchase) =>
                    _buildRecentPurchaseItem(
                      iconAsset: purchase['iconAsset'],
                      iconColor: purchase['iconColor'],
                      title: purchase['categoryName'],
                      date: purchase['date'],
                      price: '\$${purchase['price'].toStringAsFixed(2)}',
                      isDarkMode: isDarkMode,
                    ),
                ),
              ],

              // Show message if no recent purchases
              if (controller.recentPurchases.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF333333) : Colors.grey[200]!,
                    ),
                  ),
                  child: Text(
                    'No recent purchases found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
              ],

              SizedBox(height: screenHeight * 0.03),

              // View all Purchase Button
  SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      onPressed: () {
        // Route to Pro or Non-Pro Savings based on subscription status
        final sub = Get.find<SubscriptionService>();
        if (sub.isActivePro) {
          Get.toNamed(AppRoutes.proSavings);
        } else {
          Get.toNamed(AppRoutes.nonProSavings);
        }
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isDarkMode ? const Color(0xFF333333) : Colors.grey[300]!,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      child: Text(
        'view_all'.tr,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPurchaseItem({
    required String iconAsset,
    required Color iconColor,
    required String title,
    required String date,
    required String price,
    required bool isDarkMode,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF333333) : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  iconAsset,
                  width: 20,
                  height: 20,
                  color: iconColor,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.shopping_bag,
                      color: iconColor,
                      size: 20,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final bool isDarkMode;
  final double originalPrice;
  final double withToolPrice;
  final double savingsAmount;

  BarChartPainter({
    required this.isDarkMode,
    required this.originalPrice,
    required this.withToolPrice,
    required this.savingsAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const double spacing = 20.0; // Increased spacing for better fit
    final double availableWidth = size.width - 60; // Reserve space for y-axis labels and margins
    final double barWidth = (availableWidth - 2 * spacing) / 3;
    final double maxHeight = size.height * 0.7; // Adjusted for better vertical fit

    // Calculate max value for scaling
    final List<double> values = [originalPrice, withToolPrice, savingsAmount];
    final double maxValue = values.reduce((a, b) => a > b ? a : b);
    final double scaleFactor = maxValue > 0 ? maxHeight / maxValue : 1.0;

    final double originalPriceHeight = originalPrice * scaleFactor;
    final double withToolHeight = withToolPrice * scaleFactor;
    final double savingHeight = savingsAmount * scaleFactor;

    final double startX = 50.0; // Fixed left margin for y-axis and labels

    // Draw Y-axis
    paint.color = isDarkMode ? const Color(0xFF333333) : Colors.grey[300]!;
    paint.strokeWidth = 1;
    canvas.drawLine(
      Offset(startX - 10, 0),
      Offset(startX - 10, maxHeight),
      paint,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw grid lines and labels
    const int numLines = 4;
    for (int i = 0; i <= numLines; i++) {
      double y = maxHeight - (maxHeight * i / numLines);
      double value = maxValue * i / numLines;

      paint.color = isDarkMode ? const Color(0xFF333333) : Colors.grey[300]!;
      paint.strokeWidth = 0.5;
      canvas.drawLine(
        Offset(startX - 5, y),
        Offset(size.width - 10, y),
        paint,
      );

      textPainter.text = TextSpan(
        text: '\$${value.toStringAsFixed(0)}',
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontSize: 10,
        ),
      );
      textPainter.layout();
      // Ensure y-label doesn't overflow left
      final double labelX = math.max(0, startX - textPainter.width - 5);
      textPainter.paint(canvas, Offset(labelX, y - 6));
    }

    // Draw bars with adjusted positioning
    _drawBar(
      canvas: canvas,
      x: startX,
      height: originalPriceHeight,
      maxHeight: maxHeight,
      barWidth: barWidth,
      color: Colors.grey,
      label: 'Original',
      value: originalPrice,
    );

    _drawBar(
      canvas: canvas,
      x: startX + barWidth + spacing,
      height: withToolHeight,
      maxHeight: maxHeight,
      barWidth: barWidth,
      color: Colors.blue,
      label: 'With Tool',
      value: withToolPrice,
    );

    _drawBar(
      canvas: canvas,
      x: startX + 2 * (barWidth + spacing),
      height: savingHeight,
      maxHeight: maxHeight,
      barWidth: barWidth,
      color: Colors.green,
      label: 'Savings',
      value: savingsAmount,
    );
  }

  void _drawBar({
    required Canvas canvas,
    required double x,
    required double height,
    required double maxHeight,
    required double barWidth,
    required Color color,
    required String label,
    required double value,
  }) {
    final paint = Paint()..color = color;

    // Draw the bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          maxHeight - height,
          barWidth,
          height,
        ),
        const Radius.circular(4),
      ),
      paint,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw value above bar with overflow handling
    if (value > 0) {
      String valueText = '\$${value.toStringAsFixed(0)}';
      textPainter.text = TextSpan(
        text: valueText,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 9, // Slightly smaller font to fit better
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      double offsetX = x + (barWidth - textPainter.width) / 2;
      // Clamp to prevent overflow
      offsetX = offsetX.clamp(x - 5, x + barWidth + 5);
      textPainter.paint(
        canvas,
        Offset(
          offsetX,
          maxHeight - height - 12,
        ),
      );
    }

    // Draw label below bar
    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        fontSize: 10,
      ),
    );
    textPainter.layout();
    double labelOffsetX = x + (barWidth - textPainter.width) / 2;
    labelOffsetX = labelOffsetX.clamp(x, x + barWidth);
    textPainter.paint(
      canvas,
      Offset(
        labelOffsetX,
        maxHeight + 5,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}