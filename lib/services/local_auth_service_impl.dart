import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isSupported() async {
    try {
      // On non-web platforms, verify device support and biometric availability
      final deviceSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return deviceSupported && canCheck;
    } catch (e) {
      debugPrint('LocalAuth isSupported error: $e');
      return false;
    }
  }

  // Check if face biometrics are available (primarily for Android)
  Future<bool> hasFaceBiometrics() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.contains(BiometricType.face);
    } catch (e) {
      debugPrint('LocalAuth getAvailableBiometrics error: $e');
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Authenticate to continue'}) async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('LocalAuth authenticate error: $e');
      return false;
    }
  }
}