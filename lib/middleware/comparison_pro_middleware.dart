import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/routes/app_routes.dart';

class ComparisonProMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final sub = Get.find<SubscriptionService>();
    // Block non‑Pro users from Comparison routes entirely
    if (!sub.isActivePro) {
      Future.microtask(() {
        Get.snackbar(
          'upgradeToProToView'.tr,
          'graphsAndReports'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      });
      return const RouteSettings(name: AppRoutes.premiumPlans);
    }
    return null;
  }
}