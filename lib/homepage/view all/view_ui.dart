import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/homepage/view%20all/view_controller.dart';
import '../../Settings/appearance/ThemeController.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AllTransactionsController controller = Get.put(AllTransactionsController());
    final ThemeController themeController = Get.find<ThemeController>();
    final double screenWidth = MediaQuery.of(context).size.width;

    return Obx(() => Scaffold(
      backgroundColor: themeController.isDarkMode.value
          ? const Color(0xFF121212) // Dark background
          : Colors.white, // Light background
      appBar: AppBar(
        backgroundColor: themeController.isDarkMode.value
            ? const Color(0xFF121212)
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: themeController.isDarkMode.value ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w600,
            color: themeController.isDarkMode.value ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenWidth * 0.04),
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w700,
                  color: themeController.isDarkMode.value ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              // Transaction list
              Obx(() => Column(
                children: controller.allTransactions.map((transaction) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: screenWidth * 0.03),
                    child: _buildTransactionItem(
                      transaction.title,
                      transaction.time,
                      transaction.amount,
                      transaction.isIncome,
                      screenWidth,
                      themeController.isDarkMode.value,
                    ),
                  );
                }).toList(),
              )),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildTransactionItem(
      String title, String time, String amount, bool isIncome, double screenWidth, bool isDarkMode) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                color: isIncome
                    ? (isDarkMode ? Colors.green.withOpacity(0.2) : const Color(0xFFE8F5E9))
                    : (isDarkMode ? Colors.orange.withOpacity(0.2) : const Color(0xFFFFF3E0)),
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
                  SizedBox(height: screenWidth * 0.005),
                  Text(
                    time,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
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