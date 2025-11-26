import 'package:get/get.dart';
import 'package:flutter/widgets.dart'; // for RouteSettings
import 'package:your_expense/routes/app_routes.dart';
import 'package:your_expense/services/subscription_service.dart';

class ProUserMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final sub = Get.isRegistered<SubscriptionService>()
        ? Get.find<SubscriptionService>()
        : Get.put(SubscriptionService(), permanent: true);
    // Redirect if subscription is expired; allow navigation otherwise
    if (sub.isProUser && sub.isExpiredNow) {
        // Prompt to resubscribe and reroute to premium plans
        Future.microtask(() {
          Get.snackbar(
            'Subscription expired',
            'Your pro subscription has ended. Please renew to continue.',
            snackPosition: SnackPosition.BOTTOM,
          );
        });
        return const RouteSettings(name: AppRoutes.premiumPlans);
    }
    return null; // no redirect
  }
}