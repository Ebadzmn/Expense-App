import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ConfigService extends GetxService {
  static ConfigService get to => Get.find();

  final String baseUrl;

  ConfigService({this.baseUrl = 'http://10.10.7.106:5001/api/v1'});

  // Auth endpoints
  String get loginEndpoint => '$baseUrl/auth/login';
  String get registerEndpoint => '$baseUrl/user';
  String get verifyEmailEndpoint => '$baseUrl/auth/verify-email';
  String get resendOtpEndpoint => '$baseUrl/auth/resend-otp';
  String get forgotPasswordEndpoint => '$baseUrl/auth/forgot-password';
  String get resetPasswordEndpoint => '$baseUrl/auth/reset-password';

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

  String get monthlyBudgetEndpoint => '$baseUrl/budget/simple-monthly-budget';
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