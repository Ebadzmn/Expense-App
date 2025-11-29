import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:your_expense/Settings/appearance/ThemeController.dart';

import 'expense_controller.dart';
import 'expense_model.dart';

class ExpenseListScreen extends StatelessWidget {
  final ExpenseController _expenseController = Get.find();
  final ThemeController _themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define colors based on theme
    final backgroundColor = _themeController.isDarkModeActive
        ? Color(0xFF121212)
        : Colors.white;
    final cardColor = _themeController.isDarkModeActive
        ? Color(0xFF1E1E1E)
        : Colors.white;
    final textColor = _themeController.isDarkModeActive
        ? Colors.white
        : Colors.black;
    final secondaryTextColor = _themeController.isDarkModeActive
        ? Colors.grey.shade400
        : Colors.grey.shade600;
    final iconColor = _themeController.isDarkModeActive
        ? Colors.grey.shade400
        : Colors.grey.shade600;
    final shadowColor = _themeController.isDarkModeActive
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(screenWidth, textColor, backgroundColor),
      body: Obx(() {
        if (_expenseController.isLoading.value &&
            _expenseController.expenses.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (_expenseController.errorMessage.value.isNotEmpty) {
          return _buildErrorWidget(
            _expenseController.errorMessage.value,
            textColor,
            secondaryTextColor,
          );
        }

        if (_expenseController.expenses.isEmpty) {
          return _buildEmptyState(iconColor, textColor, secondaryTextColor);
        }

        return RefreshIndicator(
          onRefresh: () => _expenseController.loadExpenses(),
          child: ListView.builder(
            padding: EdgeInsets.all(screenWidth * 0.04),
            itemCount: _expenseController.expenses.length,
            itemBuilder: (context, index) {
              final expense = _expenseController.expenses[index];
              return _buildExpenseItem(
                context,
                expense,
                screenWidth,
                screenHeight,
                cardColor,
                textColor,
                secondaryTextColor,
                iconColor,
                shadowColor,
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add expense screen
          // Get.to(() => AddExpenseScreen());
        },
        child: Icon(Icons.add),
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
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: textColor,
          size: screenWidth * 0.05,
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'expense_list'.tr,
        style: TextStyle(
          color: textColor,
          fontSize: screenWidth * 0.045,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: textColor),
          onPressed: () => _expenseController.loadExpenses(),
        ),
      ],
    );
  }

  Widget _buildExpenseItem(
    BuildContext context,
    ExpenseItem expense,
    double screenWidth,
    double screenHeight,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color iconColor,
    Color shadowColor,
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
              color: _themeController.isDarkModeActive
                  ? Color(0xFF2D2D2D)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Center(
              child: Icon(
                Icons.receipt,
                size: screenWidth * 0.06,
                color: iconColor,
              ),
            ),
          ),

          SizedBox(width: screenWidth * 0.04),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category.isNotEmpty ? expense.category : 'expense'.tr,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  expense.note.isNotEmpty
                      ? expense.note
                      : (expense.category.isNotEmpty
                            ? expense.category
                            : 'no_description'.tr),
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    color: secondaryTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                      expense.formattedDate,
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
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    expense.formattedAmount,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: screenWidth * 0.05,
                        color: iconColor,
                      ),
                      onPressed: () {
                        _showEditExpenseDialog(context, expense);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        size: screenWidth * 0.05,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        _showDeleteConfirmationDialog(context, expense);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(
    String error,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'failed_to_load_expenses'.tr,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _expenseController.loadExpenses(),
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    Color iconColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 50, color: iconColor),
          SizedBox(height: 16),
          Text(
            'no_expenses_found'.tr,
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          Text(
            'start_adding_expenses_to_see_them'.tr,
            style: TextStyle(color: secondaryTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showEditExpenseDialog(BuildContext context, ExpenseItem expense) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isDark = _themeController.isDarkModeActive;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final fieldBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final focusBorderColor = isDark
        ? Colors.tealAccent.shade200
        : Colors.blueAccent;
    final errorColor = Colors.redAccent;

    final amountController = TextEditingController(
      text: expense.amount.toStringAsFixed(2),
    );
    String? selectedCategory = expense.category.isNotEmpty
        ? expense.category
        : null;

    final baseCategories = <String>[
      'Food',
      'Transport',
      'Groceries',
      'Eating out',
      'Other',
    ];
    final Set<String> categories = {...baseCategories};
    if ((expense.category).isNotEmpty) {
      categories.add(expense.category);
    }
    final categoryOptions = categories.toList();

    Get.defaultDialog(
      title: 'edit_expense'.tr,
      titleStyle: TextStyle(
        color: titleColor,
        fontSize: screenWidth * 0.045,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: dialogBg,
      barrierDismissible: true,
      radius: screenWidth * 0.03,
      content: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01,
        ),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'amount'.tr,
              style: TextStyle(
                color: labelColor,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onTap: () => amountController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: amountController.text.length,
              ),
              style: TextStyle(color: titleColor, fontSize: screenWidth * 0.04),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.attach_money, color: labelColor),
                filled: true,
                fillColor: fieldBg,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.018,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: focusBorderColor),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: errorColor),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            Text(
              'source'.tr,
              style: TextStyle(
                color: labelColor,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value:
                  (selectedCategory != null &&
                      categoryOptions.contains(selectedCategory))
                  ? selectedCategory
                  : null,
              icon: Icon(Icons.category, color: labelColor),
              dropdownColor: dialogBg,
              menuMaxHeight: screenHeight * 0.4,
              items: categoryOptions
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => selectedCategory = val,
              decoration: InputDecoration(
                filled: true,
                fillColor: fieldBg,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.018,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: focusBorderColor),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: errorColor),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: labelColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  child: Text('cancel'.tr),
                ),
                SizedBox(width: screenWidth * 0.03),
                ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountController.text.trim());
                    if (amt == null) {
                      Get.snackbar(
                        'invalid_amount'.tr,
                        'please_enter_valid_number'.tr,
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    if ((selectedCategory ?? '').isEmpty) {
                      Get.snackbar(
                        'invalid_category'.tr,
                        'please_select_category'.tr,
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    final ok = await _expenseController.updateExpenseItem(
                      id: expense.id,
                      amount: amt,
                      category: selectedCategory,
                    );
                    if (ok) {
                      Get.back();
                      Get.snackbar(
                        'updated'.tr,
                        'expense_updated_successfully'.tr,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    } else {
                      Get.snackbar(
                        'failed'.tr,
                        _expenseController.errorMessage.value,
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  child: Text('save'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    ExpenseItem expense,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = _themeController.isDarkModeActive;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final contentColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    Get.defaultDialog(
      title: 'delete_expense'.tr,
      titleStyle: TextStyle(
        color: titleColor,
        fontSize: screenWidth * 0.045,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: dialogBg,
      middleText: 'delete_expense_confirmation'.tr,
      middleTextStyle: TextStyle(
        color: contentColor,
        fontSize: screenWidth * 0.04,
      ),
      radius: screenWidth * 0.03,
      textCancel: 'cancel'.tr,
      cancelTextColor: titleColor,
      textConfirm: 'delete'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () async {
        final success = await _expenseController.deleteExpenseItem(expense.id);
        if (success) {
          Get.back(); // Close dialog
          Get.snackbar(
            'deleted'.tr,
            'expense_deleted_successfully'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.back(); // Close dialog
          Get.snackbar(
            'failed'.tr,
            _expenseController.errorMessage.value,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
      },
    );
  }
}
