import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/routes/app_routes.dart';

import '../home/home_controller.dart';
import '../reuseablenav/reuseablenavui.dart';
import 'analytics_controller.dart';
import '../../Settings/appearance/ThemeController.dart';

class AnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnalyticsController());
    final homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    final themeController = Get.find<ThemeController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (homeCtrl.selectedNavIndex.value != 1) {
        homeCtrl.selectedNavIndex.value = 1;
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool isDarkMode = themeController.isDarkModeActive;
    final Color backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final Color cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Color(0xFF6A6A6A);
    final Color iconBackgroundColor = isDarkMode
        ? Color(0xFF2A2A2A)
        : Colors.grey.shade200;

    return WillPopScope(
      onWillPop: () async {
        try {
          final prev = Get.previousRoute;
          int idx = 0;
          switch (prev) {
            case AppRoutes.mainHome:
              idx = 0;
              break;
            case AppRoutes.comparison:
              idx = 2;
              break;
            case AppRoutes.settings:
              idx = 3;
              break;
            default:
              idx = 0;
          }
          homeCtrl.setNavIndex(idx);
        } catch (_) {}
        return true;
      },
      child: Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(screenWidth, textColor, backgroundColor),
      body: Obx(
        () => controller.isLoading.value
            ? _buildLoadingIndicator()
            : RefreshIndicator(
                onRefresh: () async {
                  await controller.fetchIncomeSummary();
                  await controller.fetchExpenseSummary();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      children: [
                        _buildChartTypeButtons(
                          controller,
                          screenWidth,
                          iconBackgroundColor,
                          textColor,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        _buildMonthSelector(
                          controller,
                          screenWidth,
                          screenHeight,
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        _buildChartsSection(
                          controller,
                          screenWidth,
                          screenHeight,
                          iconBackgroundColor,
                          textColor,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        _buildLegend(
                          controller,
                          screenWidth,
                          textColor,
                          secondaryTextColor,
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        _buildSummaryCards(
                          controller,
                          screenWidth,
                          screenHeight,
                          cardColor,
                          textColor,
                          secondaryTextColor,
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        _buildActionsSection(
                          controller,
                          screenWidth,
                          screenHeight,
                          cardColor,
                          textColor,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: CustomBottomNavBar(isDarkMode: isDarkMode),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('loading_analytics'.tr),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    double screenWidth,
    Color textColor,
    Color backgroundColor,
  ) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'analytics'.tr,
        style: TextStyle(
          color: textColor,
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      iconTheme: IconThemeData(color: textColor),
    );
  }

  Widget _buildChartTypeButtons(
    AnalyticsController controller,
    double screenWidth,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(
            () => _buildChartTypeButton(
              'pie_chart'.tr,
              0,
              controller,
              screenWidth,
              textColor,
            ),
          ),
          Obx(
            () => _buildChartTypeButton(
              'bar_chart'.tr,
              1,
              controller,
              screenWidth,
              textColor,
            ),
          ),
          Obx(
            () => _buildChartTypeButton(
              'line_chart'.tr,
              2,
              controller,
              screenWidth,
              textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(
    String title,
    int index,
    AnalyticsController controller,
    double screenWidth,
    Color textColor,
  ) {
    bool isSelected = controller.selectedChartType.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectChartType(index),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : textColor,
              fontSize: screenWidth * 0.032,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(
    AnalyticsController controller,
    double screenWidth,
    double screenHeight,
  ) {
    return GestureDetector(
      onTap: () => _showMonthPicker(controller, screenWidth, screenHeight),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.012,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(screenWidth * 0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.getCurrentMonthAndYear(),
              style: TextStyle(
                color: const Color(0xFF2196F3),
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Icon(
              Icons.keyboard_arrow_down,
              color: const Color(0xFF2196F3),
              size: screenWidth * 0.045,
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(
    AnalyticsController controller,
    double screenWidth,
    double screenHeight,
  ) {
    final now = DateTime.now();
    final currentYear = now.year;
    final themeController = Get.find<ThemeController>();
    final bool isDarkMode = themeController.isDarkModeActive;

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: screenHeight * 0.4,
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Month',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthYear =
                      '${currentYear}-${month.toString().padLeft(2, '0')}';
                  final isSelected =
                      controller.selectedMonth.value == monthYear;

                  return GestureDetector(
                    onTap: () {
                      controller.updateMonth(monthYear);
                      Get.back();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(0xFF2196F3)
                            : (isDarkMode
                                  ? Color(0xFF2A2A2A)
                                  : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Color(0xFF2196F3)
                              : (isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          DateFormat(
                            'MMM',
                          ).format(DateTime(currentYear, month)),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode ? Colors.white : Colors.black),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Data type dropdown
  Widget _buildDataTypeDropdown(
    AnalyticsController controller,
    double screenWidth,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      width: screenWidth * 0.4,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Obx(
        () => DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: controller.selectedDataType.value,
            icon: Icon(Icons.keyboard_arrow_down, color: textColor),
            isExpanded: true,
            dropdownColor: backgroundColor,
            style: TextStyle(
              color: textColor,
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
            ),
            items: [
              DropdownMenuItem(value: 0, child: Text('income'.tr)),
              DropdownMenuItem(value: 1, child: Text('expenses'.tr)),
              DropdownMenuItem(value: 2, child: Text('Both')),
            ],
            onChanged: (int? newValue) {
              if (newValue != null) {
                controller.selectDataType(newValue);
              }
            },
          ),
        ),
      ),
    );
  }

  // Charts section
  Widget _buildChartsSection(
    AnalyticsController controller,
    double screenWidth,
    double screenHeight,
    Color iconBackgroundColor,
    Color textColor,
  ) {
    return Obx(() {
      final currentData = controller.getCurrentData();
      final hasData = currentData.isNotEmpty;

      print(
        '🎨 Building ${controller.currentDataTypeName} chart - Has data: $hasData',
      );

      if (!hasData) {
        return _buildNoDataPlaceholder(
          screenWidth,
          screenHeight,
          controller.getCurrentDataTypeTitle(),
        );
      }

      return Column(
        children: [
          // Data Type Dropdown and Chart Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChartTitle(
                controller.getCurrentDataTypeTitle(),
                screenWidth,
              ),
              _buildDataTypeDropdown(
                controller,
                screenWidth,
                iconBackgroundColor,
                textColor,
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildChart(controller, screenWidth, screenHeight, currentData),
        ],
      );
    });
  }

  Widget _buildChartTitle(String title, double screenWidth) {
    return Text(
      title,
      style: TextStyle(
        fontSize: screenWidth * 0.045,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildChart(
    AnalyticsController controller,
    double screenWidth,
    double screenHeight,
    List<ChartData> data,
  ) {
    return Container(
      height: screenHeight * 0.3,
      child: controller.selectedChartType.value == 0
          ? _buildPieChart(controller, screenWidth, screenHeight, data)
          : controller.selectedChartType.value == 1
          ? _buildBarChart(controller, screenWidth, screenHeight, data)
          : _buildLineChart(controller, screenWidth, screenHeight, data),
    );
  }

  Widget _buildPieChart(
    AnalyticsController controller,
    double screenWidth,
    double screenHeight,
    List<ChartData> data,
  ) {
    print(
      '🥧 Building ${controller.currentDataTypeName} pie chart with ${data.length} items',
    );
    return Center(
      child: CustomPaint(
        size: Size(screenWidth * 0.5, screenWidth * 0.5),
        painter: PieChartPainter(data),
      ),
    );
  }

  Widget _buildBarChart(
    AnalyticsController controller,
    double screenWidth,
    double screenHeight,
    List<ChartData> data,
  ) {
    print(
      '📊 Building ${controller.currentDataTypeName} bar chart with ${data.length} items',
    );
    return Center(
      child: Container(
        height: screenHeight * 0.25,
        width: screenWidth * 0.85,
        child: CustomPaint(painter: BarChartPainter(data)),
      ),
    );
  }

  Widget _buildLineChart(
    AnalyticsController controller,
    double screenWidth,
    double screenHeight,
    List<ChartData> data,
  ) {
    print(
      '📈 Building ${controller.currentDataTypeName} line chart with ${data.length} items',
    );
    return Center(
      child: Container(
        height: screenHeight * 0.25,
        width: screenWidth * 0.85,
        child: CustomPaint(painter: LineChartPainter(data)),
      ),
    );
  }

  Widget _buildNoDataPlaceholder(
    double screenWidth,
    double screenHeight,
    String dataType,
  ) {
    return Container(
      height: screenHeight * 0.35,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: screenWidth * 0.15,
              color: Colors.grey[400],
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'no_data_available'.trParams({'dataType': dataType}),
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[400],
              ),
            ),
            Text(
              'select_different_month_or_add_transactions'.tr,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(
    AnalyticsController controller,
    double screenWidth,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Obx(() {
      final currentData = controller.getCurrentData();
      final currentTotal = controller.getCurrentTotal();
      final dataType = controller.getCurrentDataTypeTitle();

      print('📖 Building legend - $dataType: ${currentData.length} items');

      if (currentData.isEmpty) {
        return _buildNoDataLegend(screenWidth, textColor, dataType);
      }

      return _buildLegendSection(
        'data_breakdown'.trParams({'dataType': dataType}),
        currentData,
        currentTotal,
        screenWidth,
        textColor,
        secondaryTextColor,
      );
    });
  }

  Widget _buildLegendSection(
    String title,
    List<ChartData> data,
    double total,
    double screenWidth,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        ...data.map((item) {
          final percentage = total > 0
              ? (item.value / total * 100).toStringAsFixed(1)
              : '0.0';
          print('📊 Legend item: ${item.label} - ${item.value} ($percentage%)');
          return _buildLegendItem(
            item.label,
            '\$${item.value.toStringAsFixed(0)} ($percentage%)',
            item.color,
            screenWidth,
            textColor,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNoDataLegend(
    double screenWidth,
    Color textColor,
    String dataType,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Text(
        'no_data_selected_month'.trParams({'dataType': dataType}),
        style: TextStyle(
          fontSize: screenWidth * 0.035,
          color: textColor.withOpacity(0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    String amount,
    Color color,
    double screenWidth,
    Color textColor,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.02),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.025,
            height: screenWidth * 0.025,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(fontSize: screenWidth * 0.032, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    AnalyticsController controller,
    double screenWidth,
    double screenHeight,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'total_expenses'.tr,
              controller.getFormattedTotalExpenses(),
              Icons.arrow_downward,
              Colors.orange,
              screenWidth,
              screenHeight,
              cardColor,
              textColor,
              secondaryTextColor,
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: _buildSummaryCard(
              'total_income'.tr,
              controller.getFormattedTotalIncome(),
              Icons.arrow_upward,
              Colors.green,
              screenWidth,
              screenHeight,
              cardColor,
              textColor,
              secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color iconColor,
    double screenWidth,
    double screenHeight,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: screenWidth * 0.05),
              SizedBox(width: screenWidth * 0.02),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            amount,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
    AnalyticsController controller,
    double screenWidth,
    double screenHeight,
    Color cardColor,
    Color textColor,
  ) {
    final sub = Get.find<SubscriptionService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'actions'.tr,
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        GestureDetector(
          onTap: controller.onExpensesClick,
          child: _buildActionItem(
            'expenses'.tr,
            screenWidth,
            cardColor,
            textColor,
          ),
        ),
        GestureDetector(
          onTap: controller.onIncomeClick,
          child: _buildActionItem(
            'income'.tr,
            screenWidth,
            cardColor,
            textColor,
          ),
        ),
        GestureDetector(
          onTap: () {
            if (!sub.isActivePro) {
              Get.snackbar(
                'Pro Required',
                'Export report is only available for Pro users.',
                snackPosition: SnackPosition.BOTTOM,
              );
              Get.toNamed(AppRoutes.premiumPlans);
            } else {
              controller.onExportReportClick();
            }
          },
          child: _buildActionItem(
            'export_report'.tr + (!sub.isActivePro ? '  🔒' : ''),
            screenWidth,
            cardColor,
            textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    String title,
    double screenWidth,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: textColor.withOpacity(0.7),
            size: screenWidth * 0.04,
          ),
        ],
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<ChartData> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double total = data.fold(0.0, (sum, item) => sum + item.value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = data[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<ChartData> data;

  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final themeController = Get.find<ThemeController>();
    final bool isDarkMode = themeController.isDarkModeActive;
    final Color gridColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color textColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    final chartHeight = size.height * 0.7;
    final chartTop = size.height * 0.1;
    final chartBottom = chartTop + chartHeight;
    final chartLeft = size.width * 0.1;
    final chartRight = size.width * 0.95;
    final chartWidth = chartRight - chartLeft;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final maxVal = data.isNotEmpty
        ? data.fold(0.0, (max, item) => math.max(max, item.value)) * 1.1
        : 100.0;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w400,
    );

    // Draw horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = chartBottom - (chartHeight * i / 5);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final value = (maxVal * i / 5).toInt();
      final painter = TextPainter(
        text: TextSpan(text: '\$${value ~/ 1000}K', style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(2, y - painter.height / 2));
    }

    if (data.isEmpty) return;

    final totalBars = data.length;
    final barWidth = chartWidth / (totalBars * 1.5) * 0.8;
    final barGap = (chartWidth - (barWidth * totalBars)) / (totalBars + 1);
    double currentX = chartLeft + barGap;

    final categoryTextStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < totalBars; i++) {
      final barHeight = (data[i].value / maxVal) * chartHeight;
      final y = chartBottom - barHeight;

      final barPaint = Paint()
        ..color = data[i].color
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(currentX, y, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);

      final valueText = TextPainter(
        text: TextSpan(
          text: '\$${data[i].value.toInt()}',
          style: categoryTextStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      valueText.paint(
        canvas,
        Offset(
          currentX + (barWidth - valueText.width) / 2,
          y - valueText.height - 2,
        ),
      );

      final labelPainter = TextPainter(
        text: TextSpan(text: data[i].label, style: categoryTextStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final labelX = currentX + (barWidth - labelPainter.width) / 2;
      final labelY = chartBottom + 8;
      labelPainter.paint(canvas, Offset(labelX, labelY));

      currentX += barWidth + barGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<ChartData> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final themeController = Get.find<ThemeController>();
    final bool isDarkMode = themeController.isDarkModeActive;
    final Color gridColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final Color textColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    final chartHeight = size.height * 0.7;
    final chartTop = size.height * 0.1;
    final chartBottom = chartTop + chartHeight;
    final chartLeft = size.width * 0.1;
    final chartRight = size.width * 0.95;
    final chartWidth = chartRight - chartLeft;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final maxVal = data.isNotEmpty
        ? data.fold(0.0, (max, item) => math.max(max, item.value)) * 1.1
        : 100.0;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w400,
    );

    // Draw horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = chartBottom - (chartHeight * i / 5);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final value = (maxVal * i / 5).toInt();
      final painter = TextPainter(
        text: TextSpan(text: '\$${value ~/ 1000}K', style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(2, y - painter.height / 2));
    }

    if (data.isEmpty) return;

    final xLabels = data.map((item) => item.label).toList();
    final totalPoints = xLabels.length;

    final categoryTextStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Draw x-axis labels
    for (int i = 0; i < totalPoints; i++) {
      final x = totalPoints > 1
          ? chartLeft + (i / (totalPoints - 1)) * chartWidth
          : chartLeft + chartWidth / 2;

      final labelPainter = TextPainter(
        text: TextSpan(text: xLabels[i], style: categoryTextStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final labelX = x - labelPainter.width / 2;
      final labelY = chartBottom + 8;
      labelPainter.paint(canvas, Offset(labelX, labelY));
    }

    final linePaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;

    // Draw line and points
    if (data.length == 1) {
      // Single point
      final x = chartLeft + chartWidth / 2;
      final y = chartBottom - (data[0].value / maxVal) * chartHeight;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    } else {
      // Multiple points
      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final x = chartLeft + (i / (data.length - 1)) * chartWidth;
        final y = chartBottom - (data[i].value / maxVal) * chartHeight;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        canvas.drawCircle(Offset(x, y), 4, pointPaint);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
