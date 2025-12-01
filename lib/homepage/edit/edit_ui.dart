// views/monthly_budget_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Settings/appearance/ThemeController.dart';
import 'edit_controller.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/routes/app_routes.dart';

class MonthlyBudgetScreen extends StatelessWidget {
  MonthlyBudgetScreen({super.key});

  final TextEditingController _budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final BudgetController budgetController = Get.put(BudgetController());
    final SubscriptionService sub = Get.find<SubscriptionService>();
    final bool isDarkMode = themeController.isDarkModeActive;

    final Color backgroundColor = isDarkMode ? Color(0xFF121212) : Color(0xFFF8F9FA);
    final Color cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDarkMode ? Colors.grey[400]! : Color(0xFF6A6A6A);
    final Color borderColor = isDarkMode ? Color(0xFF333333) : Color(0xFFE0E0E0);
    final Color lightBorderColor = isDarkMode ? Color(0xFF444444) : Color(0xFFF0F0F0);
    final Color hintTextColor = isDarkMode ? Colors.grey[500]! : Color(0xFF9E9E9E);
    final Color iconBackgroundColor = isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFF8F9FA);
    final Color primaryColor = const Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "monthly_budget".tr,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Get.offAllNamed('/mainHome'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: () {
              budgetController.refreshData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await budgetController.refreshData();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Current Monthly Budget Section
              _buildCurrentBudgetSection(
                budgetController,
                cardColor,
                textColor,
                secondaryTextColor,
                isDarkMode,
              ),

              const SizedBox(height: 32),

              // Edit Budget Section
              _buildEditBudgetSection(
                budgetController,
                sub,
                cardColor,
                borderColor,
                textColor,
                hintTextColor,
                secondaryTextColor,
                primaryColor,
              ),

              const SizedBox(height: 32),

              // Select Category Section
              _buildCategorySection(
                cardColor,
                iconBackgroundColor,
                borderColor,
                textColor,
                isDarkMode,
              ),

              const SizedBox(height: 16),

              // Add Custom Category Button
              _buildAddCategoryButton(cardColor, borderColor, textColor),

              const SizedBox(height: 32),

              // Budget Distribution Section
              _buildBudgetDistributionSection(
                budgetController,
                textColor,
                cardColor,
                lightBorderColor,
                secondaryTextColor,
                iconBackgroundColor,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBudgetSection(
      BudgetController budgetController,
      Color cardColor,
      Color textColor,
      Color secondaryTextColor,
      bool isDarkMode,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode
            ? null
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => Column(
        children: [
          Text(
            'current_monthly_budget'.tr,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),

          if (budgetController.isLoading.value)
            CircularProgressIndicator(color: textColor)
          else if (!budgetController.budgetExists.value)
            Column(
              children: [
                Icon(
                  Icons.money_off,
                  size: 32,
                  color: secondaryTextColor,
                ),
                SizedBox(height: 8),
                Text(
                  'No Budget Set',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create your first budget below',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            Column(
              children: [
                Text(
                  '\$${budgetController.monthlyBudget.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Month: ${budgetController.displayMonth}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
        ],
      )),
    );
  }

  Widget _buildEditBudgetSection(
      BudgetController budgetController,
      SubscriptionService sub,
      Color cardColor,
      Color borderColor,
      Color textColor,
      Color hintTextColor,
      Color secondaryTextColor,
      Color primaryColor,
      ) {
    final bool isBlocked = (!sub.isActivePro && budgetController.budgetExists.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'edit_your_budget'.tr,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _budgetController,
            decoration: InputDecoration(
              hintText: 'enter_amount'.tr,
              hintStyle: TextStyle(
                color: hintTextColor,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontFamily: 'Inter',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              budgetController.setEditBudgetAmount(value);
            },
            readOnly: isBlocked,
            enabled: !isBlocked,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: hintTextColor, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                size: 12,
                color: hintTextColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'budget_change_info'.tr,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
        if (isBlocked) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'upgrade_title'.tr,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'upgrade_subtitle'.tr,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Confirm Button
        Obx(() => SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: budgetController.isLoading.value
                ? null
                : () {
                    final blocked = (!sub.isActivePro && budgetController.budgetExists.value);
                    if (blocked) {
                      Get.snackbar(
                        'upgrade_title'.tr,
                        'upgrade_subtitle'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.blue,
                        colorText: Colors.white,
                      );
                      Get.toNamed(AppRoutes.monthlyBudgetNonPro);
                      return;
                    }

                    final amount = double.tryParse(_budgetController.text);
                    if (amount != null && amount > 0) {
                      budgetController.updateMonthlyBudget(amount);
                    } else {
                      Get.snackbar(
                        'Error'.tr,
                        'Please enter a valid amount'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: budgetController.isLoading.value
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Obx(() {
                    final blocked = (!sub.isActivePro && budgetController.budgetExists.value);
                    return Text(
                      blocked ? ('upgrade_now'.tr + '  🔒') : 'confirm'.tr,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    );
                  }),
          ),
        )),
      ],
    );
  }

  Widget _buildCategorySection(
      Color cardColor,
      Color iconBackgroundColor,
      Color borderColor,
      Color textColor,
      bool isDarkMode,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_category'.tr,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDarkMode
                ? null
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCategoryItem('food'.tr, 'assets/icons/soft-drink-01.png',
                  iconBackgroundColor, borderColor, textColor),
              _buildCategoryItem('transport'.tr, 'assets/icons/car.png',
                  iconBackgroundColor, borderColor, textColor),
              _buildCategoryItem('groceries'.tr, 'assets/icons/Groceries.png',
                  iconBackgroundColor, borderColor, textColor),
              _buildCategoryItem('eating_out'.tr, 'assets/icons/eating_out.png',
                  iconBackgroundColor, borderColor, textColor),
              _buildCategoryItem('home'.tr, 'assets/icons/home_icon.png',
                  iconBackgroundColor, borderColor, textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetDistributionSection(
      BudgetController budgetController,
      Color textColor,
      Color cardColor,
      Color lightBorderColor,
      Color secondaryTextColor,
      Color iconBackgroundColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'budget_distribution'.tr,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textColor,
              ),
            ),
            SizedBox(width: 8),
            Obx(() => Text(
              '(${budgetController.displayMonth})',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: secondaryTextColor,
              ),
            )),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (budgetController.isLoadingDistribution.value) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: textColor),
                    SizedBox(height: 8),
                    Text(
                      'loading_budget_distribution'.tr,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!budgetController.distributionExists.value) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightBorderColor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 48,
                    color: secondaryTextColor,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Budget Distribution',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Set up your budget categories to see the distribution',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Show actual budget distribution when it exists
          return Column(
            children: [
              // Total Summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: lightBorderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'total_expense'.tr,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '\$${budgetController.totalExpense.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'total_used'.tr,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '${budgetController.totalPercentageUsed.value.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: budgetController.totalPercentageUsed.value > 100
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Categories List
              ...budgetController.budgetDistribution.map((category) =>
                  _buildBudgetListItem(
                    budgetController.getCategoryName(category.categoryId),
                    '\$${category.budgetAmount.toStringAsFixed(2)}',
                    '${category.percentageUsed.toStringAsFixed(1)}%',
                    'Remaining: \$${category.remaining.toStringAsFixed(2)}',
                    budgetController.getCategoryIcon(category.categoryId),
                    cardColor,
                    lightBorderColor,
                    textColor,
                    secondaryTextColor,
                    iconBackgroundColor,
                    category.percentageUsed,
                  )
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCategoryItem(String label, String iconPath, Color iconBackgroundColor,
      Color borderColor, Color textColor) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 24,
                height: 24,
                color: textColor,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.category,
                    size: 24,
                    color: textColor,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton(Color cardColor, Color borderColor, Color textColor) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/addCategory');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: textColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.add,
                color: cardColor,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'add_custom_category'.tr,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetListItem(
      String category,
      String amount,
      String percentage,
      String remaining,
      String iconPath,
      Color cardColor,
      Color borderColor,
      Color textColor,
      Color secondaryTextColor,
      Color iconBackgroundColor,
      double percentageUsed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 18,
                height: 18,
                color: textColor,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.category,
                    size: 18,
                    color: textColor,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                Text(
                  remaining,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                  color: percentageUsed > 100 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}