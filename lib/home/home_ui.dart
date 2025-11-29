import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/reuseablenav/reuseablenavui.dart';
import 'package:your_expense/routes/app_routes.dart';
import 'package:your_expense/homepage/MonthlyBudgetPage.dart';
import 'package:your_expense/homepage/edit/MonthlyBudgetNonPro/MonthlyBudgetNonPro.dart';
import 'package:your_expense/Settings/userprofile/profile_services.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/services/subscription_service.dart';

import 'home_controller.dart';


class MainHomeScreen extends StatelessWidget {
  final bool showBottomNav;
  const MainHomeScreen({super.key, this.showBottomNav = true});
  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final ProfileService profile = ProfileService.to;
    final ConfigService configService = ConfigService.to;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Ensure data is loaded after login when the screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureHomeDataLoaded();
      // Also ensure profile data is fetched so app bar shows user info
      try {
        profile.fetchUserProfile();
      } catch (_) {}
    });

    // Define colors based on theme
    final backgroundColor = themeController.isDarkModeActive ? Color(0xFF121212) : Colors.white;
    final cardColor = themeController.isDarkModeActive ? Color(0xFF1E1E1E) : Color(0xFFF8F9FA);
    final textColor = themeController.isDarkModeActive ? Colors.white : Colors.black;
    final secondaryTextColor = themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade600;
    final primaryColor = Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await controller.fetchBudgetData();
            await controller.fetchRecentTransactions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                SizedBox(height: screenHeight * 0.02),
                // Header with Profile, Greeting, Location, and Notification
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.personalInformation),
                      child: Container(
                      width: screenWidth * 0.12,
                      height: screenWidth * 0.12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: secondaryTextColor, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(60)),
                        child: Obx(() {
                          final imgPath = profile.profileImage.value;
                          final version = profile.imageVersion.value;
                          if (imgPath.isNotEmpty) {
                            final origin = Uri.parse(configService.baseUrl).origin;
                            final url = (imgPath.startsWith('http://') || imgPath.startsWith('https://'))
                                ? imgPath
                                : '$origin$imgPath';
                            final withVersion = version > 0 ? '$url?v=$version' : url;
                            return Image.network(
                              withVersion,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return Image.asset('assets/icons/user.png', fit: BoxFit.cover);
                              },
                            );
                          }
                          return Image.asset('assets/icons/user.png', fit: BoxFit.cover);
                        }),
                      ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.personalInformation),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => Text(
                                  profile.userName.value,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                )),
                            SizedBox(height: screenHeight * 0.005),
                           
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.navigateToNotification(),
                      child: Container(
                        width: screenWidth * 0.11,
                        height: screenWidth * 0.11,
                        decoration: BoxDecoration(
                          color: themeController.isDarkModeActive ? Color(0xFF2D2D2D) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.notifications_none, color: iconColor),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: screenWidth * 0.02,
                                  height: screenWidth * 0.02,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                // Month Dropdown Simulation
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Container(
                //       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.01),
                //       decoration: BoxDecoration(
                //         border: Border.all(color: primaryColor),
                //         borderRadius: BorderRadius.circular(screenWidth * 0.03),
                //       ),
                //       child: Row(
                //         children: [
                //           Text(
                //             controller.getCurrentMonth(),
                //             style: TextStyle(
                //               fontSize: screenWidth * 0.035,
                //               color: primaryColor,
                //             ),
                //           ),
                //           SizedBox(width: screenWidth * 0.01),
                //           Icon(
                //             Icons.arrow_drop_down,
                //             color: primaryColor,
                //             size: screenWidth * 0.04,
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),
                SizedBox(height: screenHeight * 0.03),
                // Available Balance Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'available_balance'.tr,
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Obx(() => IconButton(
                                onPressed: () {
                                  controller.isAvailableBalanceCollapsed.value =
                                      !controller.isAvailableBalanceCollapsed.value;
                                },
                                icon: Icon(
                                  controller.isAvailableBalanceCollapsed.value
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: screenWidth * 0.05,
                                ),
                              )),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Obx(() {
                        if (controller.isAvailableBalanceCollapsed.value) {
                          return Center(
                            child: SizedBox(
                              height: screenHeight * 0.06,
                              child: ElevatedButton(
                                onPressed: () {
                                  controller.isAvailableBalanceCollapsed.value = false;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF2196F3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                  ),
                                ),
                                child: Text('See available balance'),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '\$${controller.availableBalance.value.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.1,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final budget = controller.monthlyBudget.value;
                                final inc = controller.income.value;
                                final exp = controller.expense.value;
                                final sav = inc - exp;
                                final incPct = budget > 0 ? ((inc / budget) * 100).clamp(0, 999).toDouble() : 0.0;
                                final expPct = budget > 0 ? ((exp / budget) * 100).clamp(0, 999).toDouble() : 0.0;
                                final savPct = budget > 0 && sav > 0 ? ((sav / budget) * 100).clamp(0, 999).toDouble() : 0.0;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'income'.tr,
                                        '\$${inc.toStringAsFixed(2)}',
                                        Icons.arrow_upward,
                                        Colors.green,
                                        screenWidth,
                                        '+${incPct.toStringAsFixed(0)}%'
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.04),
                                    Expanded(
                                      child: _buildStatCard(
                                        'expense'.tr,
                                        '\$${exp.toStringAsFixed(2)}',
                                        Icons.arrow_downward,
                                        Colors.orange,
                                        screenWidth,
                                        '-${expPct.toStringAsFixed(0)}%'
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.04),
                                    Expanded(
                                      child: _buildStatCard(
                                        'savings'.tr,
                                        '\$${sav.toStringAsFixed(2)}',
                                        Icons.add,
                                        Colors.white,
                                        screenWidth,
                                        '+${savPct.toStringAsFixed(0)}%'
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                // Monthly Budget Section
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('monthly_budget'.tr, style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.w600, color: textColor)),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      GestureDetector(
                        onTap: () {
                          final sub = Get.find<SubscriptionService>();
                          // Non‑Pro users: allow first use, block second and send to payment page
                          final hasBudget = controller.monthlyBudget.value > 0.0;
                          if (!sub.isActivePro && hasBudget) {
                            Get.snackbar(
                              'upgradeToProToView'.tr,
                              'upgrade_subtitle'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            Get.toNamed(AppRoutes.premiumPlans);
                            return;
                          }
                          Get.to(() => MonthlyBudgetPage());
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Obx(() => FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '\$${controller.monthlyBudget.value.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.06,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              )),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04, color: iconColor),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      
                      SizedBox(height: screenHeight * 0.02),
                      Obx(() => Container(
                        width: double.infinity,
                        height: screenHeight * 0.01,
                        decoration: BoxDecoration(
                          color: themeController.isDarkModeActive ? Color(0xFF3A3A3A) : Color(0xFFC0C0C0),
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: screenWidth * 0.8 * (controller.spentPercentage.value.clamp(0, 100) / 100),
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              ),
                            ),
                          ],
                        ),
                      )),
                      SizedBox(height: screenHeight * 0.015),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                            '${'spent'.tr} \$${controller.spentAmount.value.toStringAsFixed(2)}/${controller.spentPercentage.value.clamp(0, 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500, fontSize: screenWidth * 0.035),
                          )),
                          Obx(() => Text(
                            '${'left'.tr} \$${controller.leftAmount.value.clamp(0, double.infinity).toStringAsFixed(2)}/${controller.leftPercentage.value.clamp(0, 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500, fontSize: screenWidth * 0.035),
                          )),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Obx(() {
                        final saved = controller.monthlyBudget.value - controller.spentAmount.value;
                        final savedDisplay = saved >= 0 ? saved : 0.0;
                        return Text(
                          '${'youSaved'.tr} \$${savedDisplay.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                            fontSize: screenWidth * 0.035,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                // Rate App Section
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('rate_app'.tr, style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.w600, color: textColor)),
                      SizedBox(height: screenHeight * 0.03),
                      Text(
                        'lets_grow'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'feedback_help'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secondaryTextColor, fontSize: screenWidth * 0.035),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                            child: GestureDetector(
                              onTap: () => controller.setStarRating(index + 1),
                              child: Image.asset(
                                'assets/icons/star.png',
                                width: screenWidth * 0.07,
                                height: screenWidth * 0.07,
                                color: index < controller.starRating.value ? primaryColor : iconColor,
                              ),
                            ),
                          );
                        }),
                      )),
                      SizedBox(height: screenHeight * 0.03),
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.06,
                        child: ElevatedButton(
                          onPressed: () => controller.shareExperience(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                          ),
                          child: Text(
                            'share_experience'.tr,
                            style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('recent_transaction'.tr, style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.w600, color: textColor)),
                    GestureDetector(
                      onTap: () => controller.viewAllTransactions(),
                      child: Text('view_all'.tr, style: TextStyle(color: primaryColor, fontSize: screenWidth * 0.035)),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Obx(() => controller.isLoading.value
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                  children: controller.recentTransactions.take(4).map((transaction) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                      child: _buildTransactionItem(
                        transaction.title,
                        transaction.time,
                        transaction.amount,
                        transaction.isIncome,
                        screenWidth,
                        themeController.isDarkModeActive,
                      ),
                    );
                  }).toList(),
                ),
                ),
                SizedBox(height: screenHeight * 0.03),
              ],
            ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? CustomBottomNavBar(isDarkMode: themeController.isDarkModeActive)
          : null,
    );
  }

  Widget _buildStatCard(String title, String amount, IconData icon, Color color, double screenWidth, String percentLabel) {
    return Container(
      constraints: BoxConstraints(minHeight: screenWidth * 0.20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A6EBB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.2),
      ),
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02, horizontal: screenWidth * 0.03),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fixed text overflow with FittedBox
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          // Fixed amount text with FittedBox
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: screenWidth * 0.05,
                color: color,
              ),
              SizedBox(width: screenWidth * 0.01),
              // Fixed percentage text with FittedBox
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  percentLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String time, String amount, bool isIncome, double screenWidth, bool isDarkMode) {
    return Card(
      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      margin: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                color: isDarkMode ? Color(0xFF2D2D2D) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Center(
                child: Icon(
                  isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: screenWidth * 0.05,
                  color: isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF57C00),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$$amount',
              style: TextStyle(
                color: isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF57C00),
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
