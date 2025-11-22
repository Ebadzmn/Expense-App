import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';
import '../services/token_service.dart';
import '../services/face_id_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    // Short delay to show splash UI
    await Future.delayed(const Duration(milliseconds: 600));

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    // If user hasn't seen onboarding, show it first
    if (!hasSeenOnboarding) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    // If authenticated, gate to Face Login depending on settings
    final tokenService = Get.isRegistered<TokenService>() ? Get.find<TokenService>() : null;
    final isAuthed = tokenService?.isAuthenticated == true;

    if (isAuthed) {
      bool gateToFaceLogin = false;
      if (Get.isRegistered<FaceIdService>()) {
        final faceService = Get.find<FaceIdService>();
        gateToFaceLogin = faceService.isEnabledForCurrentUser() && faceService.isLaunchGateEnabledForCurrentUser();
      }
      Get.offAllNamed(gateToFaceLogin ? AppRoutes.faceLogin : AppRoutes.mainHome);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF101316), Color(0xFF1E252B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/AppIcon.png',
                width: 84,
                height: 84,
              ),
              const SizedBox(height: 16),
              const Text(
                'YeSpend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const CircularProgressIndicator(strokeWidth: 2.5),
            ],
          ),
        ),
      ),
    );
  }
}