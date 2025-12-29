import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ConfigService extends GetxService {
  static ConfigService get to => Get.find();

  final String baseUrl;
  final String privacyPolicyUrl;
  final String termsOfUseUrl;

  ConfigService({
    // this.baseUrl = 'https://api.yespend.com/api/v1',
    this.baseUrl = 'http://10.10.7.106:5001/api/v1',
    this.privacyPolicyUrl = 'https://yespend.com/privacy',
    this.termsOfUseUrl = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  });

  // Auth endpoints
  String get loginEndpoint => '$baseUrl/auth/login';
  String get registerEndpoint => '$baseUrl/user';
  String get verifyEmailEndpoint => '$baseUrl/auth/verify-email';
  String get resendOtpEndpoint => '$baseUrl/auth/resend-otp';
  // Some backends use "forget-password" while others use "forgot-password".
  // Provide both for compatibility and prefer the explicit forget-password alias.
  String get forgetPasswordEndpoint => '$baseUrl/auth/forget-password';
  String get forgotPasswordEndpoint => '$baseUrl/auth/forgot-password';
  String get resetPasswordEndpoint => '$baseUrl/auth/reset-password';
  String get changePasswordEndpoint => '$baseUrl/auth/change-password';

  // Expense endpoints
  String get expenseEndpoint => '$baseUrl/expense';
  String get expenseOcrRawEndpoint => '$baseUrl/expense/ocr-raw';
  // Backward-compatible alias used by older code paths
  String get ocrRawEndpoint => expenseOcrRawEndpoint;

  // Income endpoints
  String get incomeEndpoint => '$baseUrl/income';
  // If backend supports income OCR later, wire here; currently expense only
  // String get incomeOcrRawEndpoint => '$baseUrl/income/ocr-raw';
  String get incomeSummaryEndpoint => '$baseUrl/income/summary';

  // Review endpoints
  String get reviewEndpoint => '$baseUrl/review';

  // Transaction and Budget endpoints
  String get recentTransactionsEndpoint => '$baseUrl/recent-transactions';

  String get budgetEndpoint {
    final now = DateTime.now();
    final monthYear = DateFormat('yyyy-MM').format(now);
    return '$baseUrl/budget/$monthYear';
  }

  String get monthlyBudgetEndpoint => '$baseUrl/budget/current';
  String get monthlyBudgetTotalEndpoint => '$baseUrl/budget/monthly';
  String get createBudgetEndpoint => '$baseUrl/budget';
  String get savingsEndpoint => '$baseUrl/savings';

  String get budgetCategoryEndpoint {
    final now = DateTime.now();
    final monthYear = DateFormat('yyyy-MM').format(now);
    return '$baseUrl/budget/$monthYear/category';
  }

  String get monthlyBudgetSimpleEndpoint => '$baseUrl/budget/simple-monthly-budget';
  String get termsAndConditionsEndpoint => '$baseUrl/terms-conditions';
  String get userProfileEndpoint => '$baseUrl/user/profile';
  String get marketplaceSearchEndpoint => '$baseUrl/marketplace/search';
  String get categoryEndpoint => '$baseUrl/category';
  // Payment endpoint (for posting successful IAP transactions)
  String get paymentEndpoint => '$baseUrl/payment';
  // Premium status endpoint (server reports entitlement and remaining days)
  String get premiumStatusEndpoint => '$baseUrl/payment/premium-status';
  // Subscription status endpoint (server verifies App/Play store receipts and entitlement)
  String get subscriptionStatusEndpoint => '$baseUrl/subscription/status';

  String getBudgetEndpoint(String monthYear) => '$baseUrl/budget/$monthYear';
  String getMonthlyBudgetSimpleEndpoint(String month) => '$baseUrl/budget/simple-monthly-budget?Month=$month';
  String getMonthlyBudgetTotalEndpoint(String month) => '$baseUrl/budget/monthly?Month=$month';
  String get notificationsEndpoint => '$baseUrl/notifications';

  // Expense report generate endpoints (by month)
  // These return binary files (PDF/CSV/Excel) for the selected month.
  // The backend is expected to accept `Month=yyyy-MM` as a query parameter.
  String getExpensePdfEndpoint(String month) => '$baseUrl/expense/generate/pdf?month=$month';
  String getExpenseCsvEndpoint(String month) => '$baseUrl/expense/generate/csv?month=$month';
  String getExpenseExcelEndpoint(String month) => '$baseUrl/expense/generate/excel?month=$month';

  // Income report generate endpoints (by month)
  // Mirrors expense endpoints; adjust base paths if backend differs.
  String getIncomePdfEndpoint(String month) => '$baseUrl/income/pdf?month=$month';
  String getIncomeCsvEndpoint(String month) => '$baseUrl/income/csv?month=$month';
  String getIncomeExcelEndpoint(String month) => '$baseUrl/income/excel?month=$month';

  // Savings report generate endpoints (by month)
  // Savings typically computed server-side as income - expense.
  String getSavingsPdfEndpoint(String month) => '$baseUrl/savings/pdf?month=$month';
  String getSavingsCsvEndpoint(String month) => '$baseUrl/savings/csv?month=$month';
  String getSavingsExcelEndpoint(String month) => '$baseUrl/savings/excel?month=$month';

  // Monthly consolidated report (explicit format endpoints to mirror others)
  // As per request: /reports/{format}?month=YYYY-MM
  String getMonthlyPdfEndpoint(String month) => '$baseUrl/reports/pdf?month=$month';
  String getMonthlyCsvEndpoint(String month) => '$baseUrl/reports/csv?month=$month';
  String getMonthlyExcelEndpoint(String month) => '$baseUrl/reports/excel?month=$month';

  String getCurrentMonth() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM').format(now);
  }

  Future<ConfigService> init() async {
    try {
      print('=== API Configuration ===');
      print('📍 Base URL: $baseUrl');
      print('📍 Login Endpoint: $loginEndpoint');
      print('📍 Register Endpoint: $registerEndpoint');
      print('📍 Verify Email Endpoint: $verifyEmailEndpoint');
      print('📍 OCR Raw Endpoint (Expense): $expenseOcrRawEndpoint');
      // Income OCR endpoint currently not supported
      print('📍 Income Summary Endpoint: $incomeSummaryEndpoint');
      print('📍 Current Month: ${getCurrentMonth()}');
      print('=========================');
      return this;
    } catch (e) {
      print('❌ ConfigService initialization error: $e');
      rethrow;
    }
  }
}
