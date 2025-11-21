import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'income_controller.dart';
import 'income_model.dart';


class IncomeListScreen extends StatelessWidget {
  final IncomeController _incomeController = Get.find();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final themeController = Get.find<ThemeController>();

    // Define colors based on theme
    final backgroundColor = themeController.isDarkModeActive ? Color(0xFF121212) : Colors.white;
    final cardColor = themeController.isDarkModeActive ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = themeController.isDarkModeActive ? Colors.white : Colors.black;
    final secondaryTextColor = themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade600;
    final shadowColor = themeController.isDarkModeActive ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1);
    final errorColor = themeController.isDarkModeActive ? Colors.red.shade300 : Colors.red;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(screenWidth, textColor, backgroundColor),
      body: Obx(() {
        if (_incomeController.isLoading.value && _incomeController.incomes.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (_incomeController.errorMessage.value.isNotEmpty && _incomeController.incomes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: errorColor),
                SizedBox(height: 16),
                Text(
                  _incomeController.errorMessage.value,
                  style: TextStyle(color: errorColor, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _incomeController.refreshIncomes,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _incomeController.refreshIncomes,
          child: ListView.builder(
            padding: EdgeInsets.all(screenWidth * 0.04),
            itemCount: _incomeController.incomes.length + (_incomeController.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _incomeController.incomes.length) {
                return _buildLoadMoreItem(screenHeight, _incomeController);
              }

              final income = _incomeController.incomes[index];
              return _buildIncomeItem(
                income,
                screenWidth,
                screenHeight,
                cardColor,
                textColor,
                secondaryTextColor,
                iconColor,
                shadowColor,
                themeController,
                _incomeController,
              );
            },
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(double screenWidth, Color textColor, Color backgroundColor) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Icon(
          Icons.arrow_back_ios,
          color: textColor,
          size: screenWidth * 0.05,
        ),
      ),
      title: Text(
        'income_list'.tr,
        style: TextStyle(
          color: textColor,
          fontSize: screenWidth * 0.045,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildIncomeItem(
      Income income,
      double screenWidth,
      double screenHeight,
      Color cardColor,
      Color textColor,
      Color secondaryTextColor,
      Color iconColor,
      Color shadowColor,
      ThemeController themeController,
      IncomeController incomeController,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              color: themeController.isDarkModeActive ? Color(0xFF2D2D2D) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Center(
              child: _getIncomeIcon(income.source, screenWidth, iconColor),
            ),
          ),

          SizedBox(width: screenWidth * 0.04),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.source,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  'income'.tr,
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    color: secondaryTextColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.008),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: screenWidth * 0.035,
                      color: secondaryTextColor,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      income.formattedDate,
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount and edit button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                income.formattedAmount,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              GestureDetector(
                onTap: () {
                  _showEditIncomeDialog(income, incomeController);
                },
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  child: Icon(
                    Icons.edit,
                    size: screenWidth * 0.05,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreItem(double screenHeight, IncomeController incomeController) {
    return Obx(() {
      if (incomeController.isLoading.value) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Container(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
        child: Center(
          child: ElevatedButton(
            onPressed: incomeController.loadMoreIncomes,
            child: Text('load_more'.tr),
          ),
        ),
      );
    });
  }

  Widget _getIncomeIcon(String source, double screenWidth, Color iconColor) {
    final iconMap = {
      'salary': Icons.work,
      'rent': Icons.home,
      'business': Icons.business,
      'gift': Icons.card_giftcard,
    };

    final icon = iconMap[source.toLowerCase()] ?? Icons.attach_money;

    return Icon(
      icon,
      size: screenWidth * 0.06,
      color: iconColor,
    );
  }

  void _showEditIncomeDialog(Income income, IncomeController incomeController) {
    final amountController = TextEditingController(text: income.amount.toString());
    // Auto-select existing amount text for quick editing
    amountController.selection = TextSelection(baseOffset: 0, extentOffset: amountController.text.length);
    String selectedSource = income.source;
    // Build source options dynamically to ensure the current value is present
    final List<String> baseSources = ['salary', 'rent', 'business', 'gift'];
    final List<String> sources = List<String>.from(baseSources);
    if (selectedSource.isNotEmpty && !sources.contains(selectedSource)) {
      sources.insert(0, selectedSource);
    }
    // Theme-aware colors for nicer dropdown visuals
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkModeActive;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.grey.shade300 : Colors.grey.shade600;
    final fieldFillColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final focusedColor = Theme.of(Get.context!).colorScheme.primary;

    Get.defaultDialog(
      title: 'edit_income'.tr,
      titleStyle: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: cardColor,
      barrierDismissible: true,
      radius: 16,
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'amount'.tr,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
              ],
              onTap: () {
                amountController.selection = TextSelection(baseOffset: 0, extentOffset: amountController.text.length);
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.attach_money, color: iconColor),
                filled: true,
                fillColor: fieldFillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: focusedColor, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'source'.tr,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: sources.contains(selectedSource) ? selectedSource : null,
              isExpanded: true,
              style: TextStyle(color: textColor, fontSize: 14),
              icon: Icon(Icons.arrow_drop_down_circle_outlined, color: iconColor),
              dropdownColor: cardColor,
              menuMaxHeight: 240,
              items: sources
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedSource = val;
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.category_outlined, color: iconColor),
                filled: true,
                fillColor: fieldFillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: focusedColor, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Get.back(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Text('cancel'.tr),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final amtStr = amountController.text.trim();
                final amt = double.tryParse(amtStr);
                if (amt == null) {
                  Get.snackbar('invalid_amount'.tr, 'please_enter_valid_number'.tr);
                  return;
                }

                try {
                  await incomeController.editIncome(
                    id: income.id,
                    source: selectedSource,
                    amount: amt,
                  );
                  Get.back();
                  Get.snackbar('success'.tr, 'income_updated_successfully'.tr);
                } catch (e) {
                  Get.snackbar('error'.tr, e.toString());
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Text('save_action'.tr),
              ),
            ),
          ],
        ),
      ],
    );
  }
}