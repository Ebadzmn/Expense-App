import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Settings/appearance/ThemeController.dart';
import 'model_and _controller_of_monthlybudgetpage/monthly_budget_controller.dart';

class MonthlyBudgetPage extends StatelessWidget {
  MonthlyBudgetPage({super.key});

  final TextEditingController _textEditingController = TextEditingController();
  final MonthlyBudgetController _monthlyBudgetController = Get.find();
  final ThemeController _themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Define colors based on theme
    final backgroundColor = _themeController.isDarkModeActive ? const Color(0xFF121212) : Colors.white;
    final cardColor = _themeController.isDarkModeActive ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA);
    final textColor = _themeController.isDarkModeActive ? Colors.white : Colors.black;
    final secondaryTextColor = _themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade600;
    final primaryColor = const Color(0xFF2196F3);
    final errorColor = Colors.red;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Monthly Budget',
          style: TextStyle(
            color: textColor,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() => _monthlyBudgetController.isLoading.value
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      )
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + screenHeight * 0.02),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.03),

            // Error message
            if (_monthlyBudgetController.errorMessage.value.isNotEmpty)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    child: Text(
                      _monthlyBudgetController.errorMessage.value,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: errorColor,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),

            // Current Monthly Budget Section
            Text(
              'Current Monthly Budget',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: secondaryTextColor,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _monthlyBudgetController.formatCurrency(
                          _monthlyBudgetController.currentBudget.value['totalBudget'] ?? 0.0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Month: ${_monthlyBudgetController.currentBudget.value['month'] ?? _monthlyBudgetController.getCurrentMonth()}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.04),

            // Set Your Budget Section
            Text(
              'Set Your Budget',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: secondaryTextColor,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: secondaryTextColor),
                    ),
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: textColor,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      onPressed: _monthlyBudgetController.isSettingBudget.value
                          ? null
                          : () async {
                        // Clear previous errors
                        _monthlyBudgetController.errorMessage.value = '';

                        if (_textEditingController.text.isEmpty) {
                          _monthlyBudgetController.errorMessage.value = 'Please enter a budget amount';
                          return;
                        }

                        final budgetAmount = double.tryParse(_textEditingController.text);
                        if (budgetAmount == null || budgetAmount <= 0) {
                          _monthlyBudgetController.errorMessage.value = 'Please enter a valid budget amount';
                          return;
                        }

                        final success = await _monthlyBudgetController.setMonthlyBudget(budgetAmount);
                        if (success) {
                          _textEditingController.clear(); // Clear the input field
                          Get.snackbar(
                            'Success',
                            'Monthly budget set successfully',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                      ),
                      child: _monthlyBudgetController.isSettingBudget.value
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                          : Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),

            // // Premium Feature Notice
            // Container(
            //   width: double.infinity,
            //   padding: EdgeInsets.all(screenWidth * 0.05),
            //   decoration: BoxDecoration(
            //     color: cardColor,
            //     borderRadius: BorderRadius.circular(screenWidth * 0.04),
            //   ),
            //   child: Column(
            //     children: [
            //       Icon(
            //         Icons.lock_outline,
            //         size: screenWidth * 0.08,
            //         color: secondaryTextColor,
            //       ),
            //       SizedBox(height: screenHeight * 0.015),
            //       Text(
            //         'Distribute your budget by category',
            //         textAlign: TextAlign.center,
            //         style: TextStyle(
            //           fontSize: screenWidth * 0.035,
            //           color: secondaryTextColor,
            //         ),
            //       ),
            //       SizedBox(height: screenHeight * 0.01),
            //       Text(
            //         'upgrade to Premium to unlock this feature.',
            //         textAlign: TextAlign.center,
            //         style: TextStyle(
            //           fontSize: screenWidth * 0.035,
            //           color: primaryColor,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
        ),
      )),
    );
  }
}