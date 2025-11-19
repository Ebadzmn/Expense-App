import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

// App config and core
import 'package:your_expense/config/app_config.dart';

// Services
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/services/token_service.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/services/category_service.dart';

import 'package:your_expense/services/face_id_service.dart';
import 'package:your_expense/services/local_auth_service.dart';

// Feature services (canonical locations)
import 'package:your_expense/homepage/service/transaction_service.dart';
import 'package:your_expense/homepage/service/budget_service.dart';
import 'package:your_expense/homepage/service/review_service.dart';
import 'package:your_expense/Analytics/ExpenseService.dart';
import 'package:your_expense/Analytics/income_service.dart';
import 'package:your_expense/Settings/userprofile/profile_services.dart';
import 'package:your_expense/Settings/userprofile/edit_name_service.dart';
import 'package:your_expense/Settings/userprofile/change_email_service.dart';

import 'package:your_expense/RegisterScreen/registration_api_service.dart';
import 'package:your_expense/RegisterScreen/verification_api_service.dart';
import 'package:your_expense/forget_password/forgot_password_api_service.dart';

// Comparison feature service
import 'package:your_expense/Comparison/MarketplaceService.dart';

// Controllers
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/Settings/language/language_controller.dart';

import 'package:your_expense/Analytics/expense_controller.dart';
import 'package:your_expense/add_exp/pro_user/expenseincomepro/proexpincome_controller.dart';
// Added: MonthlyBudgetController registration import
import 'package:your_expense/homepage/model_and _controller_of_monthlybudgetpage/monthly_budget_controller.dart';

import 'home/home_controller.dart';
import 'login/login_controller.dart';
import 'login/login_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Mobile Ads only on supported platforms (Android/iOS), skip web/desktop
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('⚠️ MobileAds initialization skipped: $e');
    }
  }

  // Essential services before UI
  await Get.putAsync(() => ConfigService().init());
  await Get.putAsync(() => TokenService().init());
  await Get.putAsync(() => ApiBaseService().init());
  await Get.putAsync(() => SubscriptionService().init());
  await Get.putAsync(() => CategoryService().init());
  // Face ID service should be ready before routing to allow app-launch gate
  await Get.putAsync(() => FaceIdService().init());

  // Ensure MarketplaceService is ready before any page using it
  await Get.putAsync(() => MarketplaceService().init());
  await Get.putAsync(() => TransactionService().init());
  await Get.putAsync(() => BudgetService().init());
  // ExpenseService must be ready before any controllers that depend on it
  await Get.putAsync(() => ExpenseService().init());
  // Ensure income service is ready before UI builds
  await Get.putAsync(() => IncomeService().init());
  // Ensure login dependencies are available before UI builds
  await Get.putAsync(() => LoginService().init());

  // After core services and token are ready, do local recheck and expiry enforcement only
  try {
    // Call premium status endpoint on app launch so UI reflects latest entitlement
    await SubscriptionService.to.reconcileWithServer();
  } catch (e) {
    debugPrint('[Startup] Subscription reconcile failed: $e');
  }
  // Ensure ProfileService is available before any screen calls Get.find
  await Get.putAsync(() => ProfileService().init());

  // Essential controllers before UI
  Get.put(ThemeController(), permanent: true);
  Get.put(LanguageController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  // Register LoginController so Get.find works on LoginScreen
  Get.put(LoginController(), permanent: true);
  // Register MonthlyBudgetController so MonthlyBudgetPage can Get.find it
  Get.put(MonthlyBudgetController(), permanent: true);
  // Register LocalAuthService for biometric gate used in FaceLogin
  if (!Get.isRegistered<LocalAuthService>()) {
    Get.put(LocalAuthService(), permanent: true);
  }

  // Start UI early
  runApp(AppConfig.app);

  // Continue initializing remaining services concurrently (do not await)
  Future(() async {
    await Future.wait([
      // Already initialized above; keep out of concurrent init
      Get.putAsync(() => RegistrationApiService().init()),
      Get.putAsync(() => VerificationApiService().init()),
      Get.putAsync(() => ForgotPasswordApiService().init()),
      Get.putAsync(() => ReviewService().init()),
      // IncomeService and ProfileService initialized earlier; removing from concurrent init
      Get.putAsync(() => UserService().init()),
      Get.putAsync(() => ChangeEmailService().init()),
    ]);

    // Controllers that depend on services registered above
    if (!Get.isRegistered<ExpenseController>()) {
      Get.put(ExpenseController(), permanent: true);
    }
    if (!Get.isRegistered<ProExpensesIncomeController>()) {
      Get.put(ProExpensesIncomeController(), permanent: true);
    }

    // Debug: token status
    try {
      final tokenService = Get.find<TokenService>();
      final hasToken = tokenService.getToken() != null;
      debugPrint('[Startup] Token present: $hasToken');
      if (hasToken && tokenService.isTokenValid()) {
        debugPrint('[Startup] Token valid, app ready.');
      } else {
        debugPrint('[Startup] No valid token.');
      }
    } catch (e) {
      debugPrint('[Startup] Token check failed: $e');
    }
  });
}