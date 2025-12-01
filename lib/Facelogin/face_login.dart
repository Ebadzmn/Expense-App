import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io' show Platform;
import '../../colors/app_colors.dart';
import 'face_login_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/face_id_service.dart';
import '../../services/token_service.dart';
import '../../services/local_auth_service.dart';
import 'package:flutter/foundation.dart';

class FaceLoginScreen extends StatefulWidget {
  @override
  _FaceLoginScreenState createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isAuthenticating = false;

  final FaceLoginController controller = Get.put(FaceLoginController());

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      final frontCamera = _cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      Get.snackbar(
        'Camera Error',
        'Unable to access camera. Please check permissions.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _startVerification() async {
    final tokenService = Get.isRegistered<TokenService>() ? Get.find<TokenService>() : null;
    final faceService = Get.isRegistered<FaceIdService>()
        ? Get.find<FaceIdService>()
        : Get.put(FaceIdService(), permanent: true);
    final localAuth = Get.isRegistered<LocalAuthService>()
        ? Get.find<LocalAuthService>()
        : Get.put(LocalAuthService(), permanent: true);

    if (tokenService == null || !tokenService.isTokenValid()) {
      Get.snackbar(
        'Session Expired',
        'Please login with password to continue.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!faceService.isEnabledForCurrentUser()) {
      Get.snackbar(
        'Face ID Not Enabled',
        'Enable Face ID in settings and try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Hide UI during authentication
    setState(() {
      _isAuthenticating = true;
    });

    // Stop camera to remove overlay UI immediately
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _isCameraInitialized = false;

    localAuth.isSupported().then((supported) async {
      if (!supported) {
        setState(() => _isAuthenticating = false);
        Get.snackbar(
          'Unsupported',
          'Device biometrics not available.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Android: enforce face-only by checking availability before prompting
      if (!kIsWeb && Platform.isAndroid) {
        final hasFace = await localAuth.hasFaceBiometrics();
        if (!hasFace) {
          setState(() => _isAuthenticating = false);
          Get.snackbar(
            'Face Unlock Unavailable',
            'This device does not support Face biometrics.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          // Optionally re-init camera to restore UI
          _initializeCamera();
          return;
        }
      }

      final ok = await localAuth.authenticate(
        reason: 'Authenticate to continue',
      );
      if (ok) {
        Get.offNamed(AppRoutes.mainHome);
      } else {
        setState(() => _isAuthenticating = false);
        Get.snackbar(
          'Authentication Failed',
          'Could not verify your identity with Face ID.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        // Re-init camera to restore UI for retry
        _initializeCamera();
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back arrow
        title: const Text(
          'Face Verification',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: _isAuthenticating
          ? const SizedBox.shrink() // Hide UI during biometric auth
          : GetBuilder<FaceLoginController>(
              builder: (controller) => Stack(
                children: [
                  // Camera Preview (Base Layer)
                  if (_isCameraInitialized)
                    Positioned.fill(
                      child: CameraPreview(_cameraController!),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.primary500),
                    ),

                  // Face Detection Overlay
                  if (_isCameraInitialized)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return FaceOverlayWidget(
                            screenSize: screenSize,
                            progress: _animation.value,
                            isVerifying: controller.isVerifying,
                          );
                        },
                      ),
                    ),

                  // Top Instructions
                  if (!controller.isVerifying)
                    Positioned(
                      top: 100,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Position your face within the circle and tap the button below to start verification',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),

                  // Bottom Section
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54, Colors.black87],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isCameraInitialized ? _startVerification : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary500,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.grey,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.face, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Authenticate Using Face ID',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Get.offNamed(AppRoutes.login),
                            child: const Text(
                              'Back to Login',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class FaceOverlayWidget extends StatelessWidget {
  final Size screenSize;
  final double progress;
  final bool isVerifying;

  const FaceOverlayWidget({
    Key? key,
    required this.screenSize,
    required this.progress,
    required this.isVerifying,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final center = Offset(screenSize.width / 2, screenSize.height / 2 - 50);
    final radius = screenSize.width * 0.35;

    return Stack(
      children: [
        // Dark overlay with hole using ClipPath
        ClipPath(
          clipper: CircleHoleClipper(center: center, radius: radius),
          child: Container(
            width: screenSize.width,
            height: screenSize.height,
            color: Colors.black.withOpacity(0.6),
          ),
        ),

        // Circle border and progress indicator
        CustomPaint(
          size: screenSize,
          painter: CircleBorderPainter(
            center: center,
            radius: radius,
            progress: progress,
            isVerifying: isVerifying,
          ),
        ),
      ],
    );
  }
}

class CircleHoleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  CircleHoleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holePath = Path();
    holePath.addOval(Rect.fromCircle(center: center, radius: radius));

    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

class CircleBorderPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double progress;
  final bool isVerifying;

  CircleBorderPainter({
    required this.center,
    required this.radius,
    required this.progress,
    required this.isVerifying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw circle border
    final borderPaint = Paint()
      ..color = isVerifying ? AppColors.primary500 : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, borderPaint);

    // Draw progress arc during verification
    if (isVerifying && progress > 0) {
      final progressPaint = Paint()
        ..color = AppColors.primary500
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.14159 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Draw corner guides when not verifying
    if (!isVerifying) {
      final guidePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final guideLength = 20.0;
      final positions = [
        center + Offset(-radius * 0.7, -radius * 0.7), // Top-left
        center + Offset(radius * 0.7, -radius * 0.7),  // Top-right
        center + Offset(-radius * 0.7, radius * 0.7),  // Bottom-left
        center + Offset(radius * 0.7, radius * 0.7),   // Bottom-right
      ];

      for (final pos in positions) {
        // Horizontal lines
        canvas.drawLine(
          pos + const Offset(-10, 0),
          pos + Offset(guideLength - 10, 0),
          guidePaint,
        );
        // Vertical lines
        canvas.drawLine(
          pos + const Offset(0, -10),
          pos + Offset(0, guideLength - 10),
          guidePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is CircleBorderPainter &&
        (oldDelegate.progress != progress || oldDelegate.isVerifying != isVerifying);
  }
}
// Removed camera-based overlay and progress UI for a direct Face ID flow