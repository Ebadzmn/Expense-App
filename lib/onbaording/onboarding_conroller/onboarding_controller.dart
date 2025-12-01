import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart';
import '../../services/token_service.dart';
import '../../services/face_id_service.dart';

class OnboardingController extends GetxController {
  final RxInt currentPage = 0.obs;
  final PageController pageController = PageController();

  @override
  void onInit() {
    super.onInit();
    final tokenService = Get.isRegistered<TokenService>() ? Get.find<TokenService>() : null;
    if (tokenService?.isAuthenticated == true) {
      // If authenticated, decide gate based on Face ID settings
      bool gateToFaceLogin = false;
      if (Get.isRegistered<FaceIdService>()) {
        final faceService = Get.find<FaceIdService>();
        gateToFaceLogin = faceService.isEnabledForCurrentUser() && faceService.isLaunchGateEnabledForCurrentUser();
      }
      Future.microtask(() => Get.offAllNamed(gateToFaceLogin ? AppRoutes.faceLogin : AppRoutes.mainHome));
    }
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < 2) {
      pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _markOnboardingSeenAndGoLogin();
    }
  }

  void skipToLogin() {
    _markOnboardingSeenAndGoLogin();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> _markOnboardingSeenAndGoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {}
    Get.offAllNamed(AppRoutes.login);
  }
}
