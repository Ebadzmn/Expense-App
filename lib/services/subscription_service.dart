import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'dart:async';

class SubscriptionService extends GetxService {
  static SubscriptionService get to => Get.find();
  final RxBool isInitialized = false.obs;

  // Observables for UI or checks
  final RxBool isPro = false.obs;
  final Rxn<DateTime> expiryDate = Rxn<DateTime>();
  // Raw fields from last server response for direct UI display
  final RxBool serverIsPremium = false.obs;
  final Rxn<int> serverDaysLeft = Rxn<int>();

  // Ephemeral Pro unlock (e.g., watch-ad unlock). This is NOT persisted.
  // It resets when the app process exits.
  final Rxn<DateTime> temporaryProExpiry = Rxn<DateTime>();
  Timer? _tempProTimer;

  Future<SubscriptionService> init() async {
    // Start with default non-premium state; API reconcile on launch will update.
    isPro.value = false;
    expiryDate.value = null;
    serverIsPremium.value = false;
    serverDaysLeft.value = null;
    temporaryProExpiry.value = null;
    // Enforce expiry policy immediately on app launch (no-op with defaults)
    await _enforceExpiryPolicyOnLaunch();
    isInitialized.value = true;
    return this;
  }

  void _logSnapshot(String label) {
    try {
      final expStr = expiryDate.value?.toIso8601String() ?? 'null';
      final active = isActivePro;
      final expired = isExpiredNow;
      final remain = remainingDays;
      print('[SUB] ' + label + ': pro=' + isPro.value.toString() + ', expiry=' + expStr + ', active=' + active.toString() + ', expired=' + expired.toString() + ', remainingDays=' + (remain?.toString() ?? 'null'));
    } catch (_) {}
  }

  Future<void> setSubscriptionStatus({required bool pro, DateTime? expiry}) async {
    isPro.value = pro;
    expiryDate.value = expiry;
    // Debug: print after update
    _logSnapshot('set');
  }

  // Reset all subscription-related state (used on logout or user switch)
  Future<void> reset() async {
    try {
      isPro.value = false;
      expiryDate.value = null;
      serverIsPremium.value = false;
      serverDaysLeft.value = null;
      temporaryProExpiry.value = null;
      _tempProTimer?.cancel();
      _tempProTimer = null;
      _logSnapshot('reset');
    } catch (e) {
      print('[SUB][WARN] reset failed: ' + e.toString());
    }
  }

  bool get isProUser => isPro.value;
  DateTime? get getExpiryDate => expiryDate.value;

  // Computed helpers for gating
  bool get isExpiredNow {
    // If not marked pro, treat as expired
    if (!isPro.value) return true;
    // Lifetime pro: no expiry means not expired
    final exp = expiryDate.value;
    if (exp == null) return false;
    return exp.isBefore(DateTime.now());
  }

  bool get isActivePro {
    // Active via paid subscription
    final paidActive = () {
      if (!isPro.value) return false;
      final exp = expiryDate.value;
      if (exp == null) return true; // lifetime pro
      return exp.isAfter(DateTime.now());
    }();

    // Active via temporary unlock (watch ad)
    final tempExp = temporaryProExpiry.value;
    final tempActive = tempExp != null && tempExp.isAfter(DateTime.now());

    return paidActive || tempActive;
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
    // Temporary unlock is ephemeral; do not carry over across launches
    temporaryProExpiry.value = null;
    _tempProTimer?.cancel();
    _tempProTimer = null;
  }

  Future<void> recheckAndPersist() async {
    // No local storage; simply enforce current in-memory expiry policy
    await _enforceExpiryPolicyOnLaunch();
    _logSnapshot('recheck');
  }

  // ---- Server reconciliation on launch ----
  Future<void> reconcileWithServer() async {
    try {
      final api = Get.find<ApiBaseService>();
      final config = Get.find<ConfigService>();
      print('[SUB] Reconciling subscription with server: ' + config.premiumStatusEndpoint);
      final resp = await api.request('GET', config.premiumStatusEndpoint, requiresAuth: true);

      bool serverPro = false;
      DateTime? serverExpiry;

      // Expected shape:
      // { "success": true, "data": { "isPremium": true, "daysLeft": 30 } }
      int? daysLeft;
      if (resp is Map<String, dynamic>) {
        final data = resp['data'];
        if (data is Map<String, dynamic>) {
          serverPro = (data['isPremium'] == true);
          final dl = data['daysLeft'];
          if (dl is int) {
            daysLeft = dl;
          } else if (dl is String) {
            daysLeft = int.tryParse(dl);
          }
          if (daysLeft != null) {
            // If daysLeft <= 0, treat as expired immediately
            serverExpiry = DateTime.now().add(Duration(days: daysLeft));
          } else {
            // Missing daysLeft but premium true => treat as lifetime
            // Keep expiry null to indicate lifetime pro
            serverExpiry = null;
          }
        }
      }

      // Consider premium true; if daysLeft is missing, treat as lifetime pro
      final bool confirmedPro = serverPro && ((daysLeft == null) || (daysLeft! > 0));
      // Persist server truth (confirmed entitlement only) and enforce expiry locally
      await setSubscriptionStatus(pro: confirmedPro, expiry: serverExpiry);
      // Update raw server fields for UI display
      serverIsPremium.value = serverPro;
      serverDaysLeft.value = (daysLeft != null && daysLeft >= 0) ? daysLeft : null;
      await _enforceExpiryPolicyOnLaunch();

      // Debug snapshot
      _logSnapshot('server reconcile');
    } catch (e) {
      print('[SUB][WARN] reconcileWithServer failed: ' + e.toString());
    }
  }

  // ---- Temporary unlock management (e.g., Watch Ad) ----
  void grantTemporaryPro(Duration duration) {
    try {
      final until = DateTime.now().add(duration);
      temporaryProExpiry.value = until;
      _tempProTimer?.cancel();
      _tempProTimer = Timer(duration, () {
        clearTemporaryPro();
      });
      _logSnapshot('grantTemporaryPro(' + duration.inSeconds.toString() + 's)');
    } catch (e) {
      print('[SUB][WARN] grantTemporaryPro failed: ' + e.toString());
    }
  }

  void clearTemporaryPro() {
    temporaryProExpiry.value = null;
    _tempProTimer?.cancel();
    _tempProTimer = null;
    _logSnapshot('clearTemporaryPro');
  }
}