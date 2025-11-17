import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'token_service.dart';

class FaceIdService extends GetxService {
  static FaceIdService get to => Get.find();

  SharedPreferences? _prefs;

  Future<FaceIdService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  String _keyForUser(String? userId) {
    if (userId == null || userId.isEmpty) return 'face_id_enabled_global';
    return 'face_id_enabled_$userId';
  }

  String _launchGateKeyForUser(String? userId) {
    if (userId == null || userId.isEmpty) return 'face_id_launch_gate_global';
    return 'face_id_launch_gate_$userId';
  }

  Future<void> enableForCurrentUser() async {
    final tokenService = Get.find<TokenService>();
    final userId = tokenService.getUserId();
    await _prefs?.setBool(_keyForUser(userId), true);
  }

  Future<void> disableForCurrentUser() async {
    final tokenService = Get.find<TokenService>();
    final userId = tokenService.getUserId();
    await _prefs?.setBool(_keyForUser(userId), false);
  }

  bool isEnabledForCurrentUser() {
    final tokenService = Get.find<TokenService>();
    final userId = tokenService.getUserId();
    return _prefs?.getBool(_keyForUser(userId)) ?? false;
  }

  Future<void> enableForUser(String userId) async {
    await _prefs?.setBool(_keyForUser(userId), true);
  }

  bool isEnabledForUser(String userId) {
    return _prefs?.getBool(_keyForUser(userId)) ?? false;
  }

  Future<void> clearForUser(String userId) async {
    await _prefs?.remove(_keyForUser(userId));
  }

  Future<void> enableGlobally() async {
    await _prefs?.setBool('face_id_enabled_global', true);
  }

  bool isEnabledGlobally() {
    return _prefs?.getBool('face_id_enabled_global') ?? false;
  }

  // App-launch gate persistence
  Future<void> setLaunchGateForCurrentUser(bool enabled) async {
    final tokenService = Get.find<TokenService>();
    final userId = tokenService.getUserId();
    await _prefs?.setBool(_launchGateKeyForUser(userId), enabled);
  }

  bool isLaunchGateEnabledForCurrentUser() {
    final tokenService = Get.find<TokenService>();
    final userId = tokenService.getUserId();
    return _prefs?.getBool(_launchGateKeyForUser(userId)) ?? false;
  }

  Future<void> setLaunchGateForUser(String userId, bool enabled) async {
    await _prefs?.setBool(_launchGateKeyForUser(userId), enabled);
  }

  bool isLaunchGateEnabledForUser(String userId) {
    return _prefs?.getBool(_launchGateKeyForUser(userId)) ?? false;
  }
}