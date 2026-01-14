import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:your_expense/services/iap_service.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:your_expense/common/webview_screen.dart';

import '../appearance/ThemeController.dart';

// Top-level load indicator to confirm this file is loaded by the route
final _paymentUiLoaded = (() {
  print('[IAP] paymentui.dart library loaded');
  return true;
})();

class PremiumPlansScreen extends StatefulWidget {
  const PremiumPlansScreen({super.key});

  @override
  State<PremiumPlansScreen> createState() => _PremiumPlansScreenState();
}

class _PremiumPlansScreenState extends State<PremiumPlansScreen> {
  late final ThemeController themeController;
  late final IapService iap;
  String? selectedProductId; // require explicit user selection

  @override
  void initState() {
    super.initState();
    themeController = Get.find<ThemeController>();
    iap = Get.isRegistered<IapService>()
        ? Get.find<IapService>()
        : Get.put(IapService());
    // init IAP (will also query products and listen for purchases)
    print('[IAP] PremiumPlansScreen init: calling iap.init()');
    iap.init();
    // mark UI as active so IAP can gate auto-processing appropriately
    iap.paymentUiActive.value = true;
  }

  @override
  void dispose() {
    // mark UI inactive
    iap.paymentUiActive.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[IAP] PremiumPlansScreen build()');
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final sub = Get.find<SubscriptionService>();

    return Obx(
      () => Scaffold(
        backgroundColor: themeController.isDarkModeActive
            ? const Color(0xFF121212)
            : const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: themeController.isDarkModeActive
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFF8F9FA),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: themeController.isDarkModeActive
                  ? Colors.white
                  : Colors.black,
              size: screenWidth * 0.05,
            ),
            onPressed: () {
              Get.back();
            },
          ),
          title: Text(
            'premium_plans'.tr,
            style: TextStyle(
              color: themeController.isDarkModeActive
                  ? Colors.white
                  : Colors.black,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: (sub.isPro.value && sub.isActivePro)
            // Pro user view
            ? _buildProUserScreen(screenWidth, screenHeight)
            // Normal purchase flow view
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.03),

                      // Restore Purchases (iOS only)
                      if (defaultTargetPlatform == TargetPlatform.iOS)
                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.06,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: iap.isLoading,
                            builder: (context, loading, __) {
                              return OutlinedButton(
                                onPressed: loading
                                    ? null
                                    : () async {
                                        try {
                                          iap.isLoading.value = true;
                                          await iap.restorePurchases();
                                        } finally {
                                          iap.isLoading.value = false;
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: const Color(0xFF2196F3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.03,
                                    ),
                                  ),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Restore Purchases',
                                        style: TextStyle(
                                          color: const Color(0xFF2196F3),
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),

                      // Header Section
                      Text(
                        'premium_header'.tr,
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w600,
                          color: themeController.isDarkModeActive
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'premium_subheader'.tr,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: themeController.isDarkModeActive
                              ? Colors.grey[400]
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Monthly Plan
                      ValueListenableBuilder<List<ProductDetails>>(
                        valueListenable: iap.products,
                        builder: (context, products, _) {
                          // debug print for quick diagnosis
                          debugPrint(
                            'IAP products: ${products.map((p) => p.id).toList()}',
                          );

                          ProductDetails? monthly;
                          try {
                            monthly = products.firstWhere(
                              (p) => p.id == IapService.monthlyId,
                            );
                          } catch (_) {
                            monthly = null;
                          }

                          final displayTitle =
                              (monthly?.title?.isNotEmpty == true)
                                  ? monthly!.title
                                  : 'monthly_plan'.tr;
                          final displayPrice =
                              (monthly != null && (monthly.price).isNotEmpty)
                                  ? monthly.price
                                  : '';

                          return GestureDetector(
                            onTap: () {
                              setState(
                                () => selectedProductId = IapService.monthlyId,
                              );
                              debugPrint(
                                'Selected product id: ' +
                                    (selectedProductId ?? 'null'),
                              );
                            },
                            child: _buildPlanCard(
                              title: displayTitle,
                              price: displayPrice,
                              // trialText: 'free_trial'.tr,
                              isRecommended: false,
                              isSelected:
                                  selectedProductId == IapService.monthlyId,
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              isDarkMode: themeController.isDarkModeActive,
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Yearly Plan
                      ValueListenableBuilder<List<ProductDetails>>(
                        valueListenable: iap.products,
                        builder: (context, products, _) {
                          ProductDetails? yearly;
                          try {
                            yearly = products.firstWhere(
                              (p) => p.id == IapService.yearlyId,
                            );
                          } catch (_) {
                            yearly = null;
                          }

                          final displayTitle =
                              (yearly?.title?.isNotEmpty == true)
                                  ? yearly!.title
                                  : 'yearly_plan'.tr;
                          final displayPrice =
                              (yearly != null && (yearly.price).isNotEmpty)
                                  ? yearly.price
                                  : '';

                          return GestureDetector(
                            onTap: () {
                              // if yearly product not available, don't change selection to it
                              if (yearly == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Yearly plan is not available yet. Try reinstalling the app from Play Store or wait a few minutes.'
                                          .tr,
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(
                                () => selectedProductId = IapService.yearlyId,
                              );
                              debugPrint(
                                'Selected product id: ' +
                                    (selectedProductId ?? 'null'),
                              );
                            },
                            child: _buildPlanCard(
                              title: displayTitle,
                              price: displayPrice,

                              isRecommended: true,
                              isSelected:
                                  selectedProductId == IapService.yearlyId,
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              saveText: 'save_percentage'.tr,
                              isDarkMode: themeController.isDarkModeActive,
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // What's Included Section
                      Text(
                        'whats_included'.tr,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: themeController.isDarkModeActive
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      _buildFeatureItem(
                        'feature_1'.tr,
                        screenWidth,
                        screenHeight,
                        isDarkMode: themeController.isDarkModeActive,
                      ),

                      _buildFeatureItem(
                        'feature_2'.tr,
                        screenWidth,
                        screenHeight,
                        isDarkMode: themeController.isDarkModeActive,
                      ),

                      _buildFeatureItem(
                        'feature_3'.tr,
                        screenWidth,
                        screenHeight,
                        isDarkMode: themeController.isDarkModeActive,
                      ),

                      SizedBox(height: screenHeight * 0.06),

                      // Store availability notice (helps iOS/web users understand requirements)
                      ValueListenableBuilder<bool>(
                        valueListenable: iap.isAvailable,
                        builder: (context, available, _) {
                          if (available) return const SizedBox.shrink();
                          final bool isiOS =
                              defaultTargetPlatform == TargetPlatform.iOS;
                          return Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange.shade700,
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Text(
                                      'Store not available'.tr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Text(
                                  isiOS
                                      ? 'iOS e in-app purchase dekhte TestFlight diye install korun, App Store Connect e product IDs set kore Sandbox account e login korun.'
                                      : 'This device does not support in-app purchases. Please install from Play Store or App Store.',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.032,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Upgrade Button
                      ValueListenableBuilder<List<ProductDetails>>(
                        valueListenable: iap.products,
                        builder: (context, products, _) {
                          // find selected ProductDetails (may be null)
                          ProductDetails? selected;
                          try {
                            selected = products.firstWhere(
                              (p) => p.id == selectedProductId,
                            );
                          } catch (_) {
                            selected = null;
                          }

                          return SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.06,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: iap.isLoading,
                              builder: (context, loading, __) {
                                final bool isDisabledStyle =
                                    loading || selected == null;

                                return ElevatedButton(
                                  onPressed: () async {
                                    // prevent double taps while loading
                                    if (loading) return;

                                    // Guard: if store is not available (e.g., web or unsupported), block upgrade
                                    if (!iap.isAvailable.value) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'In-app purchases are not available on this device. Please use Play Store or App Store.'
                                                .tr,
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // If no plan selected, block and prompt selection
                                    if (selected == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Please choose Monthly or Yearly before upgrading.'
                                                .tr,
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // normal flow
                                    debugPrint(
                                      'Upgrade pressed for product id: ' +
                                          (selected.id),
                                    );
                                    await iap.buy(selected!);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDisabledStyle
                                        ? Colors.grey
                                        : const Color(0xFF2196F3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.03,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          selected == null
                                              ? 'Select a plan'
                                              : 'upgrade_now'.tr,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final cfg = Get.find<ConfigService>();
                              await launchUrl(
                                Uri.parse(cfg.privacyPolicyUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: const Text('Privacy Policy'),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () async {
                              final cfg = Get.find<ConfigService>();
                              await launchUrl(
                                Uri.parse(cfg.termsOfUseUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: const Text('Terms of Use'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProUserScreen(double screenWidth, double screenHeight) {
    final isDarkMode = themeController.isDarkModeActive;
    final sub = Get.find<SubscriptionService>();
    // Touch reactive values so Obx rebuilds
    final bool serverPremium = sub.serverIsPremium.value;
    final int? serverDays = sub.serverDaysLeft.value;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              size: screenWidth * 0.2,
              color: const Color(0xFF2196F3),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'payment_success_title'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'payment_success_subtitle'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: isDarkMode ? Colors.grey[300] : const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Premium Active',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  // Show only API-provided fields as requested
                  // (Removing computed Remaining days / expiry to avoid off-by-one confusion)
                  SizedBox(height: screenHeight * 0.01),
                  // Show raw entitlement snapshot based on server-derived state
                  Text(
                    'isPremium: ' + (serverPremium ? 'true' : 'false'),
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: isDarkMode
                          ? Colors.grey[300]
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    'daysLeft: ' + ((serverDays ?? 0).toString()),
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: isDarkMode
                          ? Colors.grey[300]
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            SizedBox(
              width: double.infinity,
              height: screenHeight * 0.06,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
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
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,

    required bool isRecommended,
    required bool isSelected,
    required double screenWidth,
    required double screenHeight,
    required bool isDarkMode,
    String? saveText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2196F3)
              : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: screenWidth * 0.05,
                  height: screenWidth * 0.05,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2196F3)
                          : (isDarkMode
                                ? Colors.grey.shade600
                                : Colors.grey.shade400),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: screenWidth * 0.025,
                            height: screenWidth * 0.025,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        )
                      : null,
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
                      SizedBox(height: screenHeight * 0.005),
                      if (price.isNotEmpty)
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (saveText != null || isRecommended) ...[
              SizedBox(height: screenHeight * 0.015),
              Row(
                children: [
                  SizedBox(width: screenWidth * 0.08),
                  if (saveText != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Text(
                        saveText,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (isRecommended) ...[
                    SizedBox(width: screenWidth * 0.02),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Text(
                        'recommended'.tr,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: const Color(0xFF2196F3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    String text,
    double screenWidth,
    double screenHeight, {
    required bool isDarkMode,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.06,
            height: screenWidth * 0.06,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2196F3),
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: screenWidth * 0.035,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
