import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/routes/app_routes.dart';

import '../../ad_helper.dart';

class MonthlyBudgetPro extends StatefulWidget {
  const MonthlyBudgetPro({super.key});

  @override
  State<MonthlyBudgetPro> createState() => _MonthlyBudgetProState();
}

class _MonthlyBudgetProState extends State<MonthlyBudgetPro> {
  final ThemeController themeController = Get.find<ThemeController>();
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
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
      onAdDismissed: () {
        Get.snackbar(
          'unlocked'.tr,
          'unlocked_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: themeController.isDarkModeActive
              ? Colors.grey[800]
              : Colors.green,
          colorText: Colors.white,
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Get.offAllNamed('/monthlyBudget');
          }
        });
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
        }
      },
      onAdFailed: () {
        Get.offAllNamed('/monthlyBudget'); // Navigate even if ad fails
        if (mounted) {
          setState(() {
            _isAdLoading = false;
          });
        }
      },
    );
  }

  void _navigateToPremiumPlans() {
    Get.toNamed(AppRoutes.premiumPlans);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = themeController.isDarkModeActive;
    final Color backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color containerColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final Color greyColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color lightGreyColor = isDarkMode ? Colors.grey[600]! : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'monthly_budget_pro'.tr,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
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
                                  color: containerColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 30,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'watch_video_unlock'.tr,
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
                    'video_message'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: greyColor,
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
                      onTap: _navigateToPremiumPlans,
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
                              'upgrade_to_pro'.tr,
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
                  'no_ads_info'.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: lightGreyColor,
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