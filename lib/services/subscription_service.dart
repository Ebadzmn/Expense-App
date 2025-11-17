import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';

class SubscriptionService extends GetxService {
  static SubscriptionService get to => Get.find();

  SharedPreferences? _prefs;
  final RxBool isInitialized = false.obs;

  // Observables for UI or checks
  final RxBool isPro = false.obs;
  final Rxn<DateTime> expiryDate = Rxn<DateTime>();

  Future<SubscriptionService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromStorage();
    // Enforce expiry policy immediately on app launch
    await _enforceExpiryPolicyOnLaunch();
    isInitialized.value = true;
    return this;
  }

  void _loadFromStorage() {
    final pro = _prefs?.getBool('sub_is_pro') ?? false;
    final expiryMillis = _prefs?.getInt('sub_expiry_millis');
    isPro.value = pro;
    expiryDate.value = expiryMillis != null ? DateTime.fromMillisecondsSinceEpoch(expiryMillis) : null;
    // Debug: print current subscription snapshot
    try {
      final expStr = expiryDate.value?.toIso8601String() ?? 'null';
      final active = isActivePro;
      final expired = isExpiredNow;
      final remain = remainingDays;
      // Consolidated debug log for quick inspection in console
      // Example: [SUB] loaded: pro=true, expiry=2025-12-31T23:59:00Z, active=true, expired=false, remainingDays=300
      print('[SUB] loaded: pro=' + pro.toString() + ', expiry=' + expStr + ', active=' + active.toString() + ', expired=' + expired.toString() + ', remainingDays=' + (remain?.toString() ?? 'null'));
    } catch (_) {}
  }

  Future<void> setSubscriptionStatus({required bool pro, DateTime? expiry}) async {
    isPro.value = pro;
    expiryDate.value = expiry;
    await _prefs?.setBool('sub_is_pro', pro);
    if (expiry != null) {
      await _prefs?.setInt('sub_expiry_millis', expiry.millisecondsSinceEpoch);
    } else {
      await _prefs?.remove('sub_expiry_millis');
    }
    // Debug: print after persisting
    try {
      final expStr = expiryDate.value?.toIso8601String() ?? 'null';
      print('[SUB] set: pro=' + pro.toString() + ', expiry=' + expStr + ', active=' + isActivePro.toString() + ', expired=' + isExpiredNow.toString());
    } catch (_) {}
  }

  bool get isProUser => isPro.value;
  DateTime? get getExpiryDate => expiryDate.value;

  // Computed helpers for gating
  bool get isExpiredNow {
    final exp = expiryDate.value;
    if (exp == null) return false; // treat null as non-expiring (lifetime)
    return exp.isBefore(DateTime.now());
  }

  bool get isActivePro {
    if (!isPro.value) return false;
    final exp = expiryDate.value;
    if (exp == null) return true; // lifetime pro
    return exp.isAfter(DateTime.now());
  }

  int? get remainingDays {
    final exp = expiryDate.value;
    if (exp == null) return null;
    final now = DateTime.now();
    if (exp.isBefore(now)) return 0;
    return exp.difference(now).inDays;
  }

  // ---- Launch-time and manual recheck helpers ----

  Future<void> _enforceExpiryPolicyOnLaunch() async {
    // If stored pro has expired, flip pro off and persist immediately
    if (isPro.value && isExpiredNow) {
      await setSubscriptionStatus(pro: false, expiry: expiryDate.value);
    }
  }

  Future<void> recheckAndPersist() async {
    _loadFromStorage();
    await _enforceExpiryPolicyOnLaunch();
    // Debug: post-recheck snapshot
    try {
      final expStr = expiryDate.value?.toIso8601String() ?? 'null';
      print('[SUB] recheck: pro=' + isPro.value.toString() + ', expiry=' + expStr + ', active=' + isActivePro.toString() + ', expired=' + isExpiredNow.toString());
    } catch (_) {}
  }

  // ---- Server reconciliation on launch ----
  Future<void> reconcileWithServer() async {
    try {
      final api = Get.find<ApiBaseService>();
      final config = Get.find<ConfigService>();
      print('[SUB] Reconciling subscription with server: ' + config.subscriptionStatusEndpoint);
      final resp = await api.request('GET', config.subscriptionStatusEndpoint, requiresAuth: true);

      // Expecting a shape like { isPro: bool, expiryMillis: int } or similar.
      bool serverPro = false;
      DateTime? serverExpiry;

      if (resp is Map<String, dynamic>) {
        // Try multiple common keys for robustness
        serverPro = (resp['isPro'] ?? resp['pro'] ?? resp['active'] ?? false) == true;

        final millis = resp['expiryMillis'] ?? resp['expiresMillis'] ?? resp['expiry_ms'];
        final iso = resp['expiry'] ?? resp['expiresAt'] ?? resp['expires_on'];

        if (millis is int) {
          serverExpiry = DateTime.fromMillisecondsSinceEpoch(millis);
        } else if (millis is String) {
          final parsedInt = int.tryParse(millis);
          if (parsedInt != null) {
            serverExpiry = DateTime.fromMillisecondsSinceEpoch(parsedInt);
          }
        }

        if (serverExpiry == null && iso is String) {
          try {
            serverExpiry = DateTime.tryParse(iso);
          } catch (_) {}
        }
      }

      // Persist server truth and enforce expiry
      await setSubscriptionStatus(pro: serverPro, expiry: serverExpiry);
      await _enforceExpiryPolicyOnLaunch();

      // Debug snapshot
      try {
        final expStr = expiryDate.value?.toIso8601String() ?? 'null';
        print('[SUB] server reconcile: pro=' + isPro.value.toString() + ', expiry=' + expStr + ', active=' + isActivePro.toString() + ', expired=' + isExpiredNow.toString());
      } catch (_) {}
    } catch (e) {
      print('[SUB][WARN] reconcileWithServer failed: ' + e.toString());
    }
  }
}