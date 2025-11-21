import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:your_expense/config/app_config.dart';
import 'package:your_expense/firebase_options.dart';

// Services
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/services/token_service.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/services/category_service.dart';
import 'package:your_expense/services/face_id_service.dart';
import 'package:your_expense/services/local_auth_service.dart';
import 'package:your_expense/services/push_notification_service.dart';
import 'package:your_expense/services/local_notifications_service.dart';

// Feature services
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
import 'package:your_expense/Comparison/MarketplaceService.dart';

// Controllers
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/Settings/language/language_controller.dart';
import 'package:your_expense/Analytics/expense_controller.dart';
import 'package:your_expense/add_exp/pro_user/expenseincomepro/proexpincome_controller.dart';
import 'package:your_expense/homepage/model_and _controller_of_monthlybudgetpage/monthly_budget_controller.dart';
import 'home/home_controller.dart';
import 'login/login_controller.dart';
import 'login/login_service.dart';
import 'package:your_expense/Settings/userprofile/profile_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background handler register
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Essential services before UI
  await Get.putAsync(() => ConfigService().init());
  await Get.putAsync(() => TokenService().init());
  await Get.putAsync(() => ApiBaseService().init());
  await Get.putAsync(() => SubscriptionService().init());
  await Get.putAsync(() => LocalNotificationsService().init());
  // Ensure LoginService is available before any controller tries to Get.find()
  await Get.putAsync(() => LoginService().init());
  // Critical services used by HomeController/UI must exist before first build
  await Get.putAsync(() => TransactionService().init());
  await Get.putAsync(() => BudgetService().init());
  await Get.putAsync(() => CategoryService().init());
  await Get.putAsync(() => ExpenseService().init());
  await Get.putAsync(() => FaceIdService().init());
  await Get.putAsync(() => ProfileService().init());

  // Start UI ASAP
  
  // Controllers before UI
  // Ensure Theme/Language controllers exist before building GetMaterialApp
  if (!Get.isRegistered<ThemeController>()) {
    Get.put(ThemeController(), permanent: true);
  }
  if (!Get.isRegistered<LanguageController>()) {
    Get.put(LanguageController(), permanent: true);
  }

  if (!Get.isRegistered<LocalAuthService>()) {
    Get.put(LocalAuthService(), permanent: true);
  }

  // Start UI
  runApp(AppConfig.app);

  // Async init (non-blocking)
  Future(() async {
    // Initialize remaining heavy services in background
    await Future.wait([
      Get.putAsync(() => MarketplaceService().init()),
      Get.putAsync(() => IncomeService().init()),
    ]);

    // Push notifications quickly after UI starts
    try {
      await Get.putAsync(() => PushNotificationService().init());
    } catch (e) {
      debugPrint('[Startup] PushNotificationService init failed: $e');
    }

    await Future.wait([
      Get.putAsync(() => RegistrationApiService().init()),
      Get.putAsync(() => VerificationApiService().init()),
      Get.putAsync(() => ForgotPasswordApiService().init()),
      Get.putAsync(() => ReviewService().init()),
      Get.putAsync(() => UserService().init()),
      Get.putAsync(() => ChangeEmailService().init()),
    ]);

    if (!Get.isRegistered<ExpenseController>()) {
      Get.put(ExpenseController(), permanent: true);
    }
    if (!Get.isRegistered<ProExpensesIncomeController>()) {
      Get.put(ProExpensesIncomeController(), permanent: true);
    }

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

    try {
      await SubscriptionService.to.reconcileWithServer();
    } catch (e) {
      debugPrint('[Startup] Subscription reconcile failed: $e');
    }
  });

  // Android storage permission (non-blocking)
  Future(() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final status = await Permission.storage.request();
        debugPrint('[Startup] Storage permission status: $status');
      } catch (e) {
        debugPrint('[Startup] Storage permission request failed: $e');
      }
    }
  });

  // Mobile Ads init moved to background after UI to avoid blocking
  Future(() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        debugPrint('⚠️ MobileAds initialization skipped: $e');
      }
    }
  });
}
