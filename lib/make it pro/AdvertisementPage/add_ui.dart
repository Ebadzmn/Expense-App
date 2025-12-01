import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/add_exp/pro_user/expenseincomepro/proexpincome_controller.dart';
import 'package:your_expense/routes/app_routes.dart';
import 'package:your_expense/services/subscription_service.dart';

import '../../ad_helper.dart';

class AppColors {
  static const Color text900 = Color(0xFF1E1E1E);
  static const Color text50 = Color(0xFFFAFAFA);
  static const Color primary = Colors.blueAccent;
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color green = Colors.green;
}

class AppStyles {
  static const double defaultRadius = 12.0;
}

class AdvertisementPage extends StatefulWidget {
  final bool isFromExpense;

  const AdvertisementPage({super.key, required this.isFromExpense});

  @override
  State<AdvertisementPage> createState() => _AdvertisementPageState();
}

class _AdvertisementPageState extends State<AdvertisementPage> {
  late final ProExpensesIncomeController proController;
  final themeController = Get.find<ThemeController>();
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    proController = Get.isRegistered<ProExpensesIncomeController>()
        ? Get.find<ProExpensesIncomeController>()
        : Get.put(ProExpensesIncomeController(), permanent: true);
    // No preload needed with simplified AdHelper
  }

  @override
  void dispose() {
    // No dispose needed with simplified AdHelper
    super.dispose();
  }

  Future<void> _showAdAndNavigate() async {
    if (_isAdLoading) return;
    setState(() {
      _isAdLoading = true;
    });

    await AdHelper.showInterstitialAd(
      onAdDismissed: () async {
        // For testing: grant temporary Pro for 1 minute
        SubscriptionService.to.grantTemporaryPro(const Duration(minutes: 1));
        await proController.unlockProFeatures(widget.isFromExpense);
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
        }
        Get.snackbar(
          'proUnlockedTitle'.tr,
          'proUnlockedMessage'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.green,
          colorText: AppColors.text50,
          duration: const Duration(seconds: 2),
        );
        // Navigate to Home after ad
        Get.offAllNamed(AppRoutes.mainHome);
      },
      onAdFailed: () {
        // Keep user on this screen and let them retry
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
        }
        Get.snackbar(
          'error'.tr,
          'Ad failed. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Obx(() => WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'watchAdTitle'.tr,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: themeController.isDarkModeActive
                  ? Colors.white
                  : AppColors.text900,
            ),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: themeController.isDarkModeActive
              ? const Color(0xFF1E1E1E)
              : AppColors.text50,
          elevation: 1,
          iconTheme: IconThemeData(
            color: themeController.isDarkModeActive
                ? Colors.white
                : Colors.black,
          ),
        ),
        backgroundColor: themeController.isDarkModeActive
            ? const Color(0xFF121212)
            : AppColors.text50,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: size.width * 0.06),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: size.height * 0.1),
                        Text(
                          'watchAdSubtitle'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: themeController.isDarkModeActive
                                ? Colors.white
                                : AppColors.text900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.05),
                        GestureDetector(
                          onTap: _isAdLoading ? null : _showAdAndNavigate,
                          child: Container(
                            width: size.width * 0.8,
                            height: size.height * 0.3,
                            decoration: BoxDecoration(
                              color: themeController.isDarkModeActive
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey[300],
                              image: const DecorationImage(
                                image: AssetImage('assets/images/adv.png'),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(
                                  AppStyles.defaultRadius),
                            ),
                            child: Center(
                              child: _isAdLoading
                                  ? CircularProgressIndicator(
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              )
                                  : Icon(
                                Icons.play_circle_filled,
                                size: 50,
                                color: themeController.isDarkModeActive
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        Text(
                          'watchAdDescription'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: themeController.isDarkModeActive
                                ? Colors.grey[400]
                                : AppColors.grey500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          'proFeaturesUnlockMessage'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: themeController.isDarkModeActive
                                ? Colors.grey[400]
                                : AppColors.grey500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.05),
                        TextButton(
                          onPressed: () {
                            Get.back(result: false);
                          },
                          child: Text(
                            'cancel'.tr,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: themeController.isDarkModeActive
                                  ? Colors.grey[400]
                                  : AppColors.grey500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}