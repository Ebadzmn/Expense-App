import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'dart:typed_data';
import 'package:your_expense/utils/download_helper_stub.dart'
    if (dart.library.html) 'package:your_expense/utils/download_helper_web.dart'
    if (dart.library.io) 'package:your_expense/utils/download_helper_io.dart';

class UploadToDriveController extends GetxController {
  // Export Data Options
  var allFiles = true.obs;
  var monthlyReports = false.obs;
  var incomeReports = false.obs;
  var expenseReports = false.obs;
  var savingsReports = false.obs;

  // File Format
  var selectedFormat = 'PDF'.obs;

  // Auto Upload
  var autoUpload = true.obs;

  // Dialog State
  var showSuccessDialog = false.obs;

  // Month selection for Monthly Reports
  final RxString selectedMonth = ''.obs;
  List<String> get monthOptions {
    final now = DateTime.now();
    final List<String> months = [];
    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      final m = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      months.add(m);
    }
    return months;
  }
  void setMonth(String m) {
    selectedMonth.value = m;
  }

  // Month selection for Income/Expense/Savings Reports
  final RxString selectedIncomeMonth = ''.obs;
  final RxString selectedExpenseMonth = ''.obs;
  final RxString selectedSavingsMonth = ''.obs;
  void setIncomeMonth(String m) {
    selectedIncomeMonth.value = m;
  }
  void setExpenseMonth(String m) {
    selectedExpenseMonth.value = m;
  }
  void setSavingsMonth(String m) {
    selectedSavingsMonth.value = m;
  }

  // Toggle functions for export data
  void toggleAllFiles() {
    allFiles.value = !allFiles.value;
    // If all files is selected, unselect others
    if (allFiles.value) {
      monthlyReports.value = false;
      incomeReports.value = false;
      expenseReports.value = false;
      savingsReports.value = false;
    }
  }

  void toggleMonthlyReports() {
    monthlyReports.value = !monthlyReports.value;
    if (monthlyReports.value) {
      allFiles.value = false;
    }
  }

  void toggleIncomeReports() {
    incomeReports.value = !incomeReports.value;
    if (incomeReports.value) {
      allFiles.value = false;
    }
  }

  void toggleExpenseReports() {
    expenseReports.value = !expenseReports.value;
    if (expenseReports.value) {
      allFiles.value = false;
    }
  }

  void toggleSavingsReports() {
    savingsReports.value = !savingsReports.value;
    if (savingsReports.value) {
      allFiles.value = false;
    }
  }

  // File format selection
  void selectFormat(String format) {
    selectedFormat.value = format;
  }

  // Auto upload toggle
  void toggleAutoUpload(bool value) {
    autoUpload.value = value;
  }

  // Download button click
  Future<void> onDownloadClick() async {
    try {
      // Require at least one of Income/Expense/Savings to be selected
      if (!(incomeReports.value || expenseReports.value || savingsReports.value || monthlyReports.value)) {
        Get.snackbar(
          'Select Report',
          'Please select Monthly, Income, Expense, or Savings and month',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 2),
          icon: Icon(Icons.warning, color: Colors.white),
        );
        return;
      }

      final config = Get.find<ConfigService>();
      final api = Get.find<ApiBaseService>();

  // Helper to resolve endpoint by type and format
  Future<void> _downloadFor(
    String type,
    String month,
  ) async {
    String endpoint;
    String ext;
    switch (selectedFormat.value) {
      case 'CSV':
        ext = 'csv';
        if (type == 'Income') {
          endpoint = config.getIncomeCsvEndpoint(month);
        } else if (type == 'Savings') {
          endpoint = config.getSavingsCsvEndpoint(month);
        } else if (type == 'Monthly') {
          endpoint = config.getMonthlyCsvEndpoint(month);
        } else {
          endpoint = config.getExpenseCsvEndpoint(month);
        }
        break;
      case 'Excel':
        ext = 'xlsx';
        if (type == 'Income') {
          endpoint = config.getIncomeExcelEndpoint(month);
        } else if (type == 'Savings') {
          endpoint = config.getSavingsExcelEndpoint(month);
        } else if (type == 'Monthly') {
          endpoint = config.getMonthlyExcelEndpoint(month);
        } else {
          endpoint = config.getExpenseExcelEndpoint(month);
        }
        break;
      case 'PDF':
      default:
        ext = 'pdf';
        if (type == 'Income') {
          endpoint = config.getIncomePdfEndpoint(month);
        } else if (type == 'Savings') {
          endpoint = config.getSavingsPdfEndpoint(month);
        } else if (type == 'Monthly') {
          endpoint = config.getMonthlyPdfEndpoint(month);
        } else {
          endpoint = config.getExpensePdfEndpoint(month);
        }
        break;
    }
    Uint8List bytes;
    try {
      bytes = await api.requestBytes('GET', endpoint, requiresAuth: true);
    } catch (e) {
      // Fallback: some backends expect 'Month' (capital M) in query
      try {
        final alt = endpoint.replaceFirst('month=', 'Month=');
        bytes = await api.requestBytes('GET', alt, requiresAuth: true);
        endpoint = alt;
      } catch (_) {
        rethrow;
      }
    }
    final filename = '$type-$month.$ext';
    await triggerDownload(filename, bytes);
        Get.snackbar(
          'Download',
          '$type $month ($ext) download started',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 2),
          icon: Icon(Icons.download, color: Colors.white),
        );
      }

      // Monthly consolidated report using explicit format endpoints (same as others)
      if (monthlyReports.value) {
        final month = (selectedMonth.value.isNotEmpty ? selectedMonth.value : config.getCurrentMonth());
        await _downloadFor('Monthly', month);
        Get.snackbar(
          'Download',
          'Monthly $month (${selectedFormat.value}) download started',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 2),
          icon: Icon(Icons.download, color: Colors.white),
        );
      }

      // Fire downloads for selected report types
      if (incomeReports.value) {
        final month = (selectedIncomeMonth.value.isNotEmpty
            ? selectedIncomeMonth.value
            : config.getCurrentMonth());
        await _downloadFor('Income', month);
      }
      if (expenseReports.value) {
        final month = (selectedExpenseMonth.value.isNotEmpty
            ? selectedExpenseMonth.value
            : config.getCurrentMonth());
        await _downloadFor('Expense', month);
      }
      if (savingsReports.value) {
        final month = (selectedSavingsMonth.value.isNotEmpty
            ? selectedSavingsMonth.value
            : config.getCurrentMonth());
        await _downloadFor('Savings', month);
      }
    } catch (e) {
      Get.snackbar(
        'Download Failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
        icon: Icon(Icons.error, color: Colors.white),
      );
    }
  }

  // Upload to drive button click
  void onUploadToDriveClick() {
    print('Upload to Drive clicked');
    if (monthlyReports.value) {
      final m = selectedMonth.value.isNotEmpty ? selectedMonth.value : 'current';
      print('Uploading monthly report for month=$m');
    }
    if (incomeReports.value) {
      final m = selectedIncomeMonth.value.isNotEmpty ? selectedIncomeMonth.value : 'current';
      print('Uploading income report for month=$m');
    }
    if (expenseReports.value) {
      final m = selectedExpenseMonth.value.isNotEmpty ? selectedExpenseMonth.value : 'current';
      print('Uploading expense report for month=$m');
    }
    if (savingsReports.value) {
      final m = selectedSavingsMonth.value.isNotEmpty ? selectedSavingsMonth.value : 'current';
      print('Uploading savings report for month=$m');
    }
    showSuccessDialog.value = true;
  }

  // Close dialog and navigate to analytics
  void closeDialogAndNavigateToAnalytics() {
    showSuccessDialog.value = false;
    // Navigate to analytics screen
    Get.offNamedUntil(AppRoutes.analytics, (route) => false);
  }

  // Get selected export options as string
  String getSelectedExportOptions() {
    List<String> selected = [];
    if (allFiles.value) selected.add('all_files'.tr);
    if (monthlyReports.value) selected.add('monthly_reports'.tr);
    if (incomeReports.value) selected.add('income_reports'.tr);
    if (expenseReports.value) selected.add('expense_reports'.tr);
    if (savingsReports.value) selected.add('savings_reports'.tr);
    return selected.join(', ');
  }

  @override
  void onInit() {
    super.onInit();
    print('Upload to Drive Controller initialized');
    // Initialize selected month to current
    final now = DateTime.now();
    selectedMonth.value = '${now.year}-${now.month.toString().padLeft(2, '0')}'
        ;
    selectedIncomeMonth.value = selectedMonth.value;
    selectedExpenseMonth.value = selectedMonth.value;
    selectedSavingsMonth.value = selectedMonth.value;
  }

  @override
  void onClose() {
    super.onClose();
    print('Upload to Drive Controller disposed');
  }
}