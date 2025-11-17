import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../services/token_service.dart';
import '../../services/face_id_service.dart';

class OnboardingController extends GetxController {
  final RxInt currentPage = 0.obs;
  final PageController pageController = PageController();

  @override
  void onInit() {
    super.onInit();
    final tokenService = Get.find<TokenService>();
    if (tokenService.isAuthenticated) {
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
      Get.offAllNamed('/login');
    }
  }

  void skipToLogin() {
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
