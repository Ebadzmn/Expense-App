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
  // Measure startup
  final appStartSw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Essential services before first frame: config, token, API
  await Future.wait([
    Get.putAsync(() => ConfigService().init()),
    Get.putAsync(() => TokenService().init()),
    Get.putAsync(() => ApiBaseService().init()),
    // Ensure Face ID preferences are available before any routing decisions
    Get.putAsync(() => FaceIdService().init()),
  ]);

  // Initialize Mobile Ads early (before first frame) to reduce load failures
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await MobileAds.instance.initialize();
      debugPrint('[Startup] MobileAds initialized early');
      // In debug builds, configure test device IDs to reliably receive test ads
      if (kDebugMode) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: const [
              // Android device hash from log hint
              '5EFC723B6630B42FFF41E5FA02E7A513',
            ],
          ),
        );
        debugPrint('[Startup] MobileAds RequestConfiguration set with testDeviceIds for debug');
      }
    } catch (e) {
      debugPrint('⚠️ MobileAds early initialization skipped: $e');
    }
  }

  // Controllers required for building the app shell
  if (!Get.isRegistered<ThemeController>()) {
    Get.put(ThemeController(), permanent: true);
  }
  if (!Get.isRegistered<LanguageController>()) {
    Get.put(LanguageController(), permanent: true);
  }
  if (!Get.isRegistered<LocalAuthService>()) {
    Get.put(LocalAuthService(), permanent: true);
  }

  // Show first frame ASAP
  runApp(AppConfig.app);
  debugPrint('[Startup] First frame shown at: ${appStartSw.elapsedMilliseconds} ms');

  // Background bootstrap (do not block UI)
  final bgSw = Stopwatch()..start();
  Future(() async {
    try {
      // Non-critical services moved to background
      await Future.wait([
        Get.putAsync(() => SubscriptionService().init()),
        Get.putAsync(() => LocalNotificationsService().init()),
        Get.putAsync(() => LoginService().init()),
      ]);

      // Feature-heavy services deferred
      await Future.wait([
        Get.putAsync(() => TransactionService().init()),
        Get.putAsync(() => BudgetService().init()),
        Get.putAsync(() => CategoryService().init()),
        Get.putAsync(() => ExpenseService().init()),
        Get.putAsync(() => ProfileService().init()),
      ]);

      // Additional feature services
      await Future.wait([
        Get.putAsync(() => MarketplaceService().init()),
        Get.putAsync(() => IncomeService().init()),
        Get.putAsync(() => RegistrationApiService().init()),
        Get.putAsync(() => VerificationApiService().init()),
        Get.putAsync(() => ForgotPasswordApiService().init()),
        Get.putAsync(() => ReviewService().init()),
        Get.putAsync(() => UserService().init()),
        Get.putAsync(() => ChangeEmailService().init()),
      ]);

      // Push notifications quickly after UI starts
      try {
        await Get.putAsync(() => PushNotificationService().init());
      } catch (e) {
        debugPrint('[Startup] PushNotificationService init failed: $e');
      }

      // Controllers that can be created after services are ready
      if (!Get.isRegistered<ExpenseController>()) {
        Get.put(ExpenseController(), permanent: true);
      }
      if (!Get.isRegistered<ProExpensesIncomeController>()) {
        Get.put(ProExpensesIncomeController(), permanent: true);
      }

      // Token check
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

      // Subscription reconcile in background
      try {
        await SubscriptionService.to.reconcileWithServer();
      } catch (e) {
        debugPrint('[Startup] Subscription reconcile failed: $e');
      }

      debugPrint('[Startup] Background bootstrap done at: ${bgSw.elapsedMilliseconds} ms');
    } catch (e) {
      debugPrint('[Startup] Background bootstrap error: $e');
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

  // (Moved) Mobile Ads initialized early above
}
