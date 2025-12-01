import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/routes/app_routes.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/Analytics/uplode_drive_controller.dart';

class UploadToDriveScreen extends StatelessWidget {
  const UploadToDriveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UploadToDriveController());
    final sub = Get.find<SubscriptionService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: _buildAppBar(screenWidth, isDark),
      body: Obx(() => Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  _buildExportDataSection(controller, screenWidth, screenHeight, isDark),
                  SizedBox(height: screenHeight * 0.03),
                  _buildFileFormatSection(controller, screenWidth, screenHeight, isDark),
                  
    
                  SizedBox(height: screenHeight * 0.04),
                  _buildActionButtons(controller, screenWidth, screenHeight, isDark),
                ],
              ),
            ),
          ),
          if (!sub.isActivePro) _buildProGateOverlay(screenWidth, screenHeight, isDark),
          // Success Dialog Overlay
          if (controller.showSuccessDialog.value)
            _buildSuccessDialog(controller, screenWidth, screenHeight, isDark),
        ],
      )),
    );
  }

  Widget _buildProGateOverlay(double screenWidth, double screenHeight, bool isDarkMode) {
    return Positioned.fill(
      child: Container(
        color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.88),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: screenWidth * 0.12, color: isDarkMode ? Colors.white70 : Colors.black54),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'upgradeToProToView'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: screenHeight * 0.008),
              Text(
                'graphsAndReports'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.premiumPlans);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12, vertical: screenHeight * 0.016),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.white, size: screenWidth * 0.05),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'upgradeNow'.tr,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double screenWidth, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Icon(
          Icons.arrow_back_ios,
          color: isDark ? Colors.white : Colors.black,
          size: screenWidth * 0.05,
        ),
      ),
      title: Text(
        'upload_to_drive'.tr,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: screenWidth * 0.045,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildConnectedAccount(double screenWidth, double screenHeight, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'connected_account'.tr,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
        Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/icons_google.png',
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'youremail@gmail.com',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'connected'.tr,
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportDataSection(UploadToDriveController controller, double screenWidth, double screenHeight, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_export_data'.tr,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
      
        _buildMonthlyReportsItem(controller, screenWidth, screenHeight, isDark),
        _buildIncomeReportsItem(controller, screenWidth, screenHeight, isDark),
        _buildExpenseReportsItem(controller, screenWidth, screenHeight, isDark),
        _buildSavingsReportsItem(controller, screenWidth, screenHeight, isDark),
      ],
    );
  }

  Widget _buildMonthlyReportsItem(UploadToDriveController controller, double screenWidth, double screenHeight, bool isDark) {
    return Obx(() {
      final isSelected = controller.monthlyReports.value;
      return GestureDetector(
        onTap: controller.toggleMonthlyReports,
        child: Container(
          margin: EdgeInsets.only(bottom: screenWidth * 0.02),
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2196F3) : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.01),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: screenWidth * 0.035,
                      )
                    : null,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'monthly_reports'.tr,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              // Month dropdown placed beside the report selector
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(screenWidth * 0.015),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(() => DropdownButton<String>(
                        value: controller.selectedMonth.value.isNotEmpty
                            ? controller.selectedMonth.value
                            : null,
                        hint: Text(
                          'select_month'.tr,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                          ),
                        ),
                        items: controller.monthOptions
                            .map(
                              (m) => DropdownMenuItem<String>(
                                value: m,
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.032,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.setMonth(val);
                          }
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: isDark ? Colors.white : Colors.black,
                          size: screenWidth * 0.045,
                        ),
                        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      )),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildIncomeReportsItem(UploadToDriveController controller, double screenWidth, double screenHeight, bool isDark) {
    return Obx(() {
      final isSelected = controller.incomeReports.value;
      return GestureDetector(
        onTap: controller.toggleIncomeReports,
        child: Container(
          margin: EdgeInsets.only(bottom: screenWidth * 0.02),
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2196F3) : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.01),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: screenWidth * 0.035,
                      )
                    : null,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'income_reports'.tr,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(screenWidth * 0.015),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(() => DropdownButton<String>(
                        value: controller.selectedIncomeMonth.value.isNotEmpty ? controller.selectedIncomeMonth.value : null,
                        hint: Text(
                          'select_month'.tr,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                          ),
                        ),
                        items: controller.monthOptions
                            .map((m) => DropdownMenuItem<String>(
                                  value: m,
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.032,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) controller.setIncomeMonth(val);
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: isDark ? Colors.white : Colors.black,
                          size: screenWidth * 0.045,
                        ),
                        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      )),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildExpenseReportsItem(UploadToDriveController controller, double screenWidth, double screenHeight, bool isDark) {
    return Obx(() {
      final isSelected = controller.expenseReports.value;
      return GestureDetector(
        onTap: controller.toggleExpenseReports,
        child: Container(
          margin: EdgeInsets.only(bottom: screenWidth * 0.02),
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2196F3) : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.01),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: screenWidth * 0.035,
                      )
                    : null,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'expense_reports'.tr,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(screenWidth * 0.015),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(() => DropdownButton<String>(
                        value: controller.selectedExpenseMonth.value.isNotEmpty ? controller.selectedExpenseMonth.value : null,
                        hint: Text(
                          'select_month'.tr,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                          ),
                        ),
                        items: controller.monthOptions
                            .map((m) => DropdownMenuItem<String>(
                                  value: m,
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.032,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) controller.setExpenseMonth(val);
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: isDark ? Colors.white : Colors.black,
                          size: screenWidth * 0.045,
                        ),
                        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      )),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSavingsReportsItem(UploadToDriveController controller, double screenWidth, double screenHeight, bool isDark) {
    return Obx(() {
      final isSelected = controller.savingsReports.value;
      return GestureDetector(
        onTap: controller.toggleSavingsReports,
        child: Container(
          margin: EdgeInsets.only(bottom: screenWidth * 0.02),
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2196F3) : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.01),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: screenWidth * 0.035,
                      )
                    : null,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'savings_reports'.tr,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(screenWidth * 0.015),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(() => DropdownButton<String>(
                        value: controller.selectedSavingsMonth.value.isNotEmpty ? controller.selectedSavingsMonth.value : null,
                        hint: Text(
                          'select_month'.tr,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                          ),
                        ),
                        items: controller.monthOptions
                            .map((m) => DropdownMenuItem<String>(
                                  value: m,
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.032,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) controller.setSavingsMonth(val);
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: isDark ? Colors.white : Colors.black,
                          size: screenWidth * 0.045,
                        ),
                        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      )),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCheckboxItem(String title, RxBool value, VoidCallback onTap, double screenWidth, bool isDark) {
    return Obx(() => GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.02),
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.05,
              height: screenWidth * 0.05,
              decoration: BoxDecoration(
                color: value.value ? const Color(0xFF2196F3) : Colors.transparent,
                border: Border.all(
                  color: value.value ? const Color(0xFF2196F3) :
                  (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.01),
              ),
              child: value.value
                  ? Icon(
                Icons.check,
                color: Colors.white,
                size: screenWidth * 0.035,
              )
                  : null,
            ),
            SizedBox(width: screenWidth * 0.03),
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildFileFormatSection(UploadToDriveController controller, double screenWidth, double screenHeight, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'choose_file_format'.tr,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
        _buildRadioItem('pdf_recommended'.tr, 'PDF', controller.selectedFormat, controller.selectFormat, screenWidth, isDark),
        _buildRadioItem('excel_xlsx'.tr, 'Excel', controller.selectedFormat, controller.selectFormat, screenWidth, isDark),
        _buildRadioItem('csv'.tr, 'CSV', controller.selectedFormat, controller.selectFormat, screenWidth, isDark),
      ],
    );
  }

  Widget _buildRadioItem(String title, String value, RxString selectedValue, Function(String) onSelect, double screenWidth, bool isDark) {
    return Obx(() => GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.02),
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.05,
              height: screenWidth * 0.05,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedValue.value == value ? const Color(0xFF2196F3) :
                  (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  width: 2,
                ),
              ),
              child: selectedValue.value == value
                  ? Center(
                child: Container(
                  width: screenWidth * 0.025,
                  height: screenWidth * 0.025,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : null,
            ),
            SizedBox(width: screenWidth * 0.03),
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    ));
  }




  Widget _buildActionButtons(UploadToDriveController controller, double screenWidth, double screenHeight, bool isDark) {
    return Column(
      children: [
        // Download Button
        GestureDetector(
          onTap: controller.onDownloadClick,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              boxShadow: isDark ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              'download'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        // Upload to Drive Button
       
      ],
    );
  }

  Widget _buildSuccessDialog(UploadToDriveController controller, double screenWidth, double screenHeight, bool isDark) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          padding: EdgeInsets.all(screenWidth * 0.06),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: screenWidth * 0.08,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'upload_successful'.tr,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'upload_success_message'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              GestureDetector(
                onTap: controller.closeDialogAndNavigateToAnalytics,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Text(
                    'ok'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}