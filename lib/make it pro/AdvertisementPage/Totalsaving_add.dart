import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:your_expense/Comparison/prosavingpage/proserviceui.dart';
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/Settings/premium/paymentui.dart';
import 'package:your_expense/routes/app_routes.dart';
import 'package:your_expense/services/subscription_service.dart';

import '../../ad_helper.dart';

class TotalSavingAdvertisement extends StatefulWidget {
  const TotalSavingAdvertisement({super.key});

  @override
  State<TotalSavingAdvertisement> createState() =>
      _TotalSavingAdvertisementState();
}

class _TotalSavingAdvertisementState extends State<TotalSavingAdvertisement> {
  final themeController = Get.find<ThemeController>();
  bool _isAdLoading = false;
  late final SubscriptionService _subscriptionService;

  @override
  void initState() {
    super.initState();
    // Initialize subscription service and bypass ad if already Pro
    _subscriptionService = Get.find<SubscriptionService>();
    if (_subscriptionService.isActivePro) {
      // Navigate directly to Pro savings if user is active Pro
      Future.microtask(() {
        Get.offNamed(AppRoutes.proSavings);
      });
      return;
    }
    // No preload needed with simplified AdHelper
  }

  @override
  void dispose() {
    // No dispose needed with simplified AdHelper
    super.dispose();
  }

  Future<void> _showAdAndNavigate() async {
    if (_isAdLoading) return;
    // If Pro is active, skip ad flow
    if (_subscriptionService.isActivePro) {
      Get.offNamed(AppRoutes.proSavings);
      return;
    }
    setState(() {
      _isAdLoading = true;
    });

    await AdHelper.showInterstitialAd(
      onAdDismissed: () {
        Get.snackbar(
          'unlocked'.tr,
          'unlockMessage'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Get.offNamed(AppRoutes.proSavings);
          }
        });
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
        }
      },
      onAdFailed: () {
        Get.offNamed(AppRoutes.proSavings);
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = themeController.isDarkModeActive;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          'comparisonPage'.tr,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDarkMode ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isAdLoading ? null : _showAdAndNavigate,
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: AssetImage('assets/icons/addfortotal.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _isAdLoading
                              ? Colors.black.withOpacity(0.7)
                              : Colors.black.withOpacity(0.3),
                        ),
                        child: Center(
                          child: _isAdLoading
                              ? CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 30,
                                  color: isDarkMode
                                      ? Colors.black
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'watchVideoToUnlock'.tr,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'watchVideoDescription'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4A90E2),
                        Color(0xFF357ABD),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PremiumPlansScreen()),
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'upgradeToPro'.tr,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'proFeatures'.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}