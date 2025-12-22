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
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Current Monthly Budget',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: secondaryTextColor,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _monthlyBudgetController.formatCurrency(
                                  _monthlyBudgetController.simpleMonthlyAmount.value ??
                                  _monthlyBudgetController.currentBudget.value?.totalBudget ??
                                  0.0),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Edit Your Budget Section
                    Text(
                      'Edit Your Budget',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          hintText: '\$ Enter amount',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: secondaryTextColor),
                          icon: Icon(Icons.attach_money, color: secondaryTextColor, size: 20),
                        ),
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: textColor,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: secondaryTextColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Changing your budget will update your available balance on the home page.',
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
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

                                final budgetAmount = double.tryParse(_textEditingController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
                                if (budgetAmount == null || budgetAmount <= 0) {
                                  _monthlyBudgetController.errorMessage.value = 'Please enter a valid budget amount';
                                  return;
                                }

                                if (_monthlyBudgetController.selectedCategory.value == null) {
                                  Get.snackbar('Select Category', 'Please select a category below to apply this budget.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.orange,
                                      colorText: Colors.white);
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
                          elevation: 0,
                        ),
                        child: _monthlyBudgetController.isSettingBudget.value
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Select Category
                    Text(
                      'Select Category',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _monthlyBudgetController.availableCategories.map((category) {
                          final isSelected = _monthlyBudgetController.selectedCategory.value == category['name'];
                          return GestureDetector(
                            onTap: () {
                              if (isSelected) {
                                _monthlyBudgetController.selectedCategory.value = null;
                              } else {
                                _monthlyBudgetController.selectedCategory.value = category['name'];
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: screenWidth * 0.03),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.015,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor.withOpacity(0.1) : cardColor,
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                border: Border.all(
                                  color: isSelected ? primaryColor : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Since we don't have real assets yet, using Icons
                                  Icon(
                                    _getIconForCategory(category['name']!),
                                    color: isSelected ? primaryColor : secondaryTextColor,
                                    size: 24,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    category['name']!,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.03,
                                      color: isSelected ? primaryColor : secondaryTextColor,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Add Custom Category Button
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add, color: textColor),
                          SizedBox(height: 4),
                          Text(
                            'Add Custom Category',
                            style: TextStyle(
                              color: textColor,
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Budget Distribution
                    Text(
                      'Budget Distribution',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    
                    // List of budget items
                    if (_monthlyBudgetController.currentBudget.value?.categories.isNotEmpty ?? false)
                      ..._monthlyBudgetController.currentBudget.value!.categories.map((catItem) {
                        return Container(
                          margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getIconForCategory(catItem.categoryId),
                                  size: 20,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  catItem.categoryId.capitalizeFirst ?? catItem.categoryId,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _monthlyBudgetController.formatCurrency(catItem.budgetAmount),
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    '${catItem.percentageUsed}%', // You might want to calculate percentage of total budget if needed
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.03,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList()
                    else
                       Center(
                         child: Padding(
                           padding: const EdgeInsets.all(20.0),
                           child: Text(
                             'No budget distribution yet',
                             style: TextStyle(color: secondaryTextColor),
                           ),
                         ),
                       ),
                      
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'eating out':
        return Icons.fastfood;
      case 'home':
        return Icons.home;
      case 'travel':
        return Icons.flight;
      case 'medicine':
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }
}
