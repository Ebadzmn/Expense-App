// lib/services/iap_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'package:your_expense/routes/app_routes.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:your_expense/services/subscription_service.dart';

class IapService {
  // Top-level load indicator to confirm service is loaded
  static final bool _iapServiceLoaded = (() {
    print('[IAP] iap_service.dart library loaded');
    return true;
  })();
  static const String monthlyId = 'com.mashiur.expenseapp.monthly';
  static const String yearlyId = 'com.mashiur.expenseapp.yearly';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  final ApiBaseService _api = Get.find<ApiBaseService>();
  final ConfigService _config = Get.find<ConfigService>();
  final SubscriptionService _sub = Get.isRegistered<SubscriptionService>()
      ? Get.find<SubscriptionService>()
      : Get.put(SubscriptionService());

  // Prevent duplicate POSTs/navigations when sandbox auto-renews or stream replays
  final Set<String> _submittedTxIds = <String>{};
  // Prevent repeated snackbars per session/transaction
  final Set<String> _shownSnackKeys = <String>{};

  final ValueNotifier<bool> isAvailable = ValueNotifier(false);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<ProductDetails>> products = ValueNotifier(const []);
  final ValueNotifier<bool> isEntitled = ValueNotifier(false);

  // Track last manual buy attempt to distinguish user-initiated flow from passive restore
  DateTime? _lastBuyAttemptAt;
  String? _lastBuyProductId;

  Future<void> init() async {
    print('[IAP] init() starting');
    isLoading.value = true;
    try {
      final available = await _iap.isAvailable();
      isAvailable.value = available;
      print('[IAP] Store availability: ' + available.toString());
      if (!available) {
        error.value = 'Store not available';
        isLoading.value = false;
        print('[IAP] Store not available, aborting init');
        _showSnackOnce('iap:init:not_available', 'IAP', 'Store not available on this device');
        return;
      }

      await queryProducts({monthlyId, yearlyId});
      _listenToPurchases();
    } catch (e) {
      error.value = e.toString();
      print('[IAP][ERROR] init: ' + e.toString());
    } finally {
      isLoading.value = false;
      print('[IAP] init() finished');
    }
  }

  void _showSnackOnce(String key, String title, String message, {SnackPosition snackPosition = SnackPosition.BOTTOM, Duration? duration}) {
    if (_shownSnackKeys.contains(key)) return;
    _shownSnackKeys.add(key);
    try {
      Get.snackbar(title, message, snackPosition: snackPosition, duration: duration ?? const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> queryProducts(Set<String> ids) async {
    try {
      final response = await _iap.queryProductDetails(ids);
      if (response.error != null) {
        error.value = response.error!.message;
        print('[IAP] queryProducts error: ' + response.error!.message);
      }
      products.value = response.productDetails;
      print('[IAP] Products loaded: ' + products.value.map((p) => p.id).toList().toString());
      if (response.notFoundIDs.isNotEmpty) {
        print('[IAP] Not found IDs: ' + response.notFoundIDs.toString());
      }
    } catch (e) {
      error.value = e.toString();
      print('[IAP][ERROR] queryProducts: ' + e.toString());
    }
  }

  Future<void> buy(ProductDetails product) async {
    try {
      // mark initiation to help handle iOS "restored" events after manual buy
      _lastBuyAttemptAt = DateTime.now();
      _lastBuyProductId = product.id;
      isLoading.value = true;
      error.value = null;
      debugPrint('[IAP] Starting purchase for product: ${product.id}');
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } on Exception catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      debugPrint('[IAP][ERROR] buy: $e');
    }
  }

  void _listenToPurchases() {
    _purchaseSub?.cancel();
    _purchaseSub = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        try {
          // Dump debug info for every purchase event (so you can inspect in logs)
          _debugDumpPurchase(purchase);

          switch (purchase.status) {
            case PurchaseStatus.pending:
              isLoading.value = true;
              debugPrint('[IAP] Purchase pending: product=${purchase.productID}');
              break;
            case PurchaseStatus.error:
              isLoading.value = false;
              error.value = purchase.error?.message ?? 'Purchase error';
              debugPrint('[IAP] Purchase error: ${purchase.error?.message}');
              break;
            case PurchaseStatus.purchased:
              isLoading.value = false;
              isEntitled.value = true;
              debugPrint('[IAP] Purchase success: status=${purchase.status}, product=${purchase.productID}, id=${purchase.purchaseID}');

              if (purchase.pendingCompletePurchase) {
                await _iap.completePurchase(purchase);
                debugPrint('[IAP] Completed pending purchase: ${purchase.purchaseID}');
              }

              // Only process server submission and navigation for active purchases
              await _postPaymentAndNavigate(purchase);
              break;
            case PurchaseStatus.restored:
              // Restored events should not auto-post to server or block new purchases.
              // Only treat entitlement as active if local subscription is not expired.
              isLoading.value = false;
              final bool active = _sub.isActivePro; // isPro && not expired
              isEntitled.value = active;
              debugPrint('[IAP] Purchase restored: product=${purchase.productID}, id=${purchase.purchaseID}, active=${active}');

              // Heuristic: if a restore arrives right after a manual buy attempt for same product,
              // treat it as purchase-completion path (iOS sometimes reports restored).
              bool initiatedRecently = false;
              try {
                initiatedRecently = _lastBuyProductId == purchase.productID &&
                    _lastBuyAttemptAt != null &&
                    DateTime.now().difference(_lastBuyAttemptAt!) < const Duration(minutes: 2);
              } catch (_) {}

              if (purchase.pendingCompletePurchase) {
                await _iap.completePurchase(purchase);
                debugPrint('[IAP] Completed pending restore: ${purchase.purchaseID}');
              }

              if (initiatedRecently && !active) {
                debugPrint('[IAP] Restore arrived after buy attempt; proceeding with payment POST and navigation.');
                await _postPaymentAndNavigate(purchase);
              } else {
                try {
                  if (active) {
                    Get.snackbar('Subscription Active', 'Your previous subscription is active.', snackPosition: SnackPosition.BOTTOM);
                  } else {
                    Get.snackbar('Subscription Expired', 'Previous subscription expired. You can subscribe again.', snackPosition: SnackPosition.BOTTOM);
                  }
                } catch (_) {}
              }
              break;
            default:
              debugPrint('[IAP] Purchase status: ${purchase.status} for product=${purchase.productID}');
              break;
          }
        } catch (e) {
          debugPrint('[IAP][ERROR] processing purchase: $e');
        }
      }
    }, onDone: () {
      isLoading.value = false;
      debugPrint('[IAP] Purchase stream done');
    }, onError: (e) {
      error.value = e.toString();
      isLoading.value = false;
      debugPrint('[IAP] Purchase stream error: $e');
    });
  }

  Future<void> _postPaymentAndNavigate(PurchaseDetails purchase) async {
    try {
      final String productId = purchase.productID;
      String? txId;
      String platform = 'unknown';

      if (purchase is GooglePlayPurchaseDetails) {
        platform = 'android';
        txId = _extractOrderIdFromGoogle(purchase, purchase);
        debugPrint('[IAP][DEBUG] extractOrderIdFromGoogle returned: $txId');
        if (txId == null || txId.isEmpty) {
          debugPrint('[IAP][ERROR] Missing Google Play orderId; aborting payment POST.');
          _showSnackOnce('iap:error:missing_google_order', 'Purchase Error', 'Missing Play Store orderId. Please retry or contact support.');
          return;
        }
      } else if (purchase is AppStorePurchaseDetails) {
        platform = 'ios';
        txId = _extractTransactionIdFromAppStore(purchase, purchase);
        debugPrint('[IAP][DEBUG] extractTransactionIdFromAppStore returned: $txId');
        if (txId == null || txId.isEmpty) {
          debugPrint('[IAP][ERROR] Missing App Store transactionId; aborting payment POST.');
          _showSnackOnce('iap:error:missing_ios_tx', 'Purchase Error', 'Missing App Store transactionId. Please retry or contact support.');
          return;
        }
      } else {
        txId = purchase.purchaseID;
        debugPrint('[IAP][DEBUG] Generic fallback purchaseID: $txId');
        if (txId == null || txId.isEmpty) {
          txId = _tryParseIdFromServerData(purchase.verificationData.serverVerificationData);
          debugPrint('[IAP][DEBUG] _tryParseIdFromServerData fallback returned: $txId');
        }
        if (txId == null || txId.isEmpty) {
          debugPrint('[IAP][ERROR] Missing transactionId from purchase; aborting payment POST.');
          _showSnackOnce('iap:error:missing_tx', 'Purchase Error', 'Missing transactionId. Please retry or contact support.');
          return;
        }
      }

      final String transactionId = txId!;

      // Show product and transaction IDs to the user for immediate visibility
      _showSnackOnce('iap:details:' + transactionId, 'Purchase Details', 'Product: ' + productId + '\nTransaction: ' + transactionId, duration: const Duration(seconds: 5));

      // Dedup: skip if this transactionId was already submitted in this session
      if (_submittedTxIds.contains(transactionId)) {
        print('[IAP][DEDUP] Already submitted transactionId=' + transactionId + ', skipping POST.');
        _showSnackOnce('iap:dedup:' + transactionId, 'IAP', 'Payment already recorded for this transaction');
        return;
      }
      _submittedTxIds.add(transactionId);
      print('[IAP] Using store transactionId: ' + transactionId + ' (platform=' + platform + ')');
      print('[IAP] Posting payment: productId=' + productId + ', transactionId=' + transactionId + ', endpoint=' + _config.paymentEndpoint);

      final body = {
        'productId': productId,
        'transactionId': transactionId,
        'platform': platform,
        'receipt': purchase.verificationData.serverVerificationData,
      };

      print('[IAP] SUBMIT: endpoint=' + _config.paymentEndpoint + ' payload=' + jsonEncode(body));

      _showSnackOnce('iap:submit:' + transactionId, 'IAP', 'Submitting payment to server...');
      final resp = await _api.request('POST', _config.paymentEndpoint, body: body, requiresAuth: true);
      print('[IAP] Payment POST success: ' + (resp is Map<String, dynamic> ? jsonEncode(resp) : resp.toString()));
      _showSnackOnce('iap:post_success:' + transactionId, 'IAP', 'Payment POST success');

      // IMPORTANT: Do not locally flip premium. Rely on server confirmation.
      // Immediately reconcile with server to reflect true entitlement.
      await _sub.reconcileWithServer();

      // Navigate to success only if server reports premium active
      final bool premiumActive = _sub.serverIsPremium.value && (_sub.serverDaysLeft.value ?? 0) > 0;
      if (premiumActive || _sub.isActivePro) {
        debugPrint('[IAP] Server confirmed premium. Navigating to success screen.');
        Get.offAllNamed(AppRoutes.paymentSuccess);
      } else {
        debugPrint('[IAP][WARN] Server did not confirm premium after POST. Showing pending message.');
        _showSnackOnce('iap:pending:' + transactionId, 'Payment Pending', 'Waiting for server to confirm your purchase. It may take a moment.');
      }
    } catch (e, st) {
      debugPrint('Payment POST failed: $e\n$st');
      final fallbackId = purchase.purchaseID ?? 'unknown';
      _showSnackOnce('iap:recorded:' + fallbackId, 'Payment Recorded', 'Purchase completed, but could not notify server right now.');
      // Allow retry later by removing from submitted set if POST failed
      if (purchase.purchaseID != null && purchase.purchaseID!.isNotEmpty) {
        _submittedTxIds.remove(purchase.purchaseID);
      }
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[IAP][ERROR] restorePurchases: $e');
      error.value = e.toString();
    }
  }

  void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
  }

  // ---------------- Debug & Helper functions ----------------

  /// Dumps purchase detail fields to console so you can inspect what the SDK returned.
  void _debugDumpPurchase(PurchaseDetails p) {
    try {
      print('=== IAP DEBUG DUMP START ===');
      print('productID: ${p.productID}');
      print('status: ${p.status}');
      print('purchaseID: ${p.purchaseID}');
      print('transactionDate: ${p.transactionDate}');
      print('verificationData.localVerificationData length: ${p.verificationData.localVerificationData.length}');
      print('verificationData.serverVerificationData length: ${p.verificationData.serverVerificationData.length}'); 
      // Print a short prefix of serverVerificationData to inspect shape safely
      final server = p.verificationData.serverVerificationData;
      final sample = server.length > 200 ? server.substring(0, 200) + '...' : server;
      debugPrint('verificationData.serverVerificationData (sample): $sample');

      // Platform specific
      if (p is GooglePlayPurchaseDetails) {
        try {
          final gp = p as GooglePlayPurchaseDetails;
          debugPrint('[IAP][ANDROID] GooglePlayPurchaseDetails.toString(): ${gp.toString()}');
          // billingClientPurchase might be null on some versions; safe access
          try {
            final billing = gp.billingClientPurchase;
            if (billing != null) {
              debugPrint('[IAP][ANDROID] billingClientPurchase.orderId: ${billing.orderId}');
              debugPrint('[IAP][ANDROID] billingClientPurchase.purchaseToken: ${billing.purchaseToken}');
              debugPrint('[IAP][ANDROID] billingClientPurchase.sku: ${billing}');
            } else {
              debugPrint('[IAP][ANDROID] billingClientPurchase is null');
            }
          } catch (e) {
            debugPrint('[IAP][WARN] error accessing billingClientPurchase fields: $e');
          }
        } catch (e) {
          debugPrint('[IAP][WARN] cannot cast to GooglePlayPurchaseDetails: $e');
        }
      } else if (p is AppStorePurchaseDetails) {
        try {
          final ap = p as AppStorePurchaseDetails;
          debugPrint('[IAP][IOS] AppStorePurchaseDetails.toString(): ${ap.toString()}');
          // Some iOS SDK versions expose transactionIdentifier somewhere; print whole object as fallback
        } catch (e) {
          debugPrint('[IAP][WARN] cannot cast to AppStorePurchaseDetails: $e');
        }
      }

      debugPrint('=== IAP DEBUG DUMP END ===');
    } catch (e) {
      print('[IAP][WARN] _debugDumpPurchase failed: $e');
    }
  }

  String? _extractOrderIdFromGoogle(GooglePlayPurchaseDetails gp, PurchaseDetails purchase) {
    try {
      print('[IAP][DEBUG] _extractOrderIdFromGoogle: trying billingClientPurchase.orderId...');
      try {
        final orderFromBillingClient = gp.billingClientPurchase?.orderId;
        print('[IAP][DEBUG] billingClientPurchase.orderId => $orderFromBillingClient');
        if (orderFromBillingClient != null && orderFromBillingClient.isNotEmpty) {
          return orderFromBillingClient;
        }
      } catch (e) {
        debugPrint('[IAP][WARN] Error reading billingClientPurchase.orderId: $e');
      }

      debugPrint('[IAP][DEBUG] trying purchase.purchaseID...');
      final purchaseId = purchase.purchaseID;
      print('[IAP][DEBUG] purchase.purchaseID => $purchaseId');
      if (purchaseId != null && purchaseId.isNotEmpty) {
        return purchaseId;
      }

      debugPrint('[IAP][DEBUG] trying parse serverVerificationData...');
      final parsed = _tryParseIdFromServerData(purchase.verificationData.serverVerificationData);
      print('[IAP][DEBUG] parsed from serverVerificationData => $parsed');
      return parsed;
    } catch (e) {
      print('[IAP][WARN] _extractOrderIdFromGoogle error: $e');
      return null;
    }
  }

  String? _extractTransactionIdFromAppStore(AppStorePurchaseDetails ap, PurchaseDetails purchase) {
    try {
      print('[IAP][DEBUG] _extractTransactionIdFromAppStore: trying purchase.purchaseID...');
      final purchaseId = purchase.purchaseID;
      print('[IAP][DEBUG] purchase.purchaseID => $purchaseId');
      if (purchaseId != null && purchaseId.isNotEmpty) {
        return purchaseId;
      }

      print('[IAP][DEBUG] trying parse serverVerificationData for iOS...');
      final parsed = _tryParseIdFromServerData(purchase.verificationData.serverVerificationData);
      print('[IAP][DEBUG] parsed from serverVerificationData => $parsed');  
      return parsed;
    } catch (e) {
      print('[IAP][WARN] _extractTransactionIdFromAppStore error: $e');   
      return null;
    }
  }

  String? _tryParseIdFromServerData(String serverData) {
    try {
      final trimmed = serverData.trim();
      debugPrint('[IAP][DEBUG] _tryParseIdFromServerData: serverData length=${serverData.length}');
      final sample = serverData.length > 200 ? serverData.substring(0, 200) + '...' : serverData;
      debugPrint('[IAP][DEBUG] serverData sample: $sample');

      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final dynamic decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) {
            debugPrint('[IAP][DEBUG] serverData JSON keys: ${decoded.keys.toList()}');
            for (final key in ['orderId', 'order_id', 'transactionId', 'transaction_id', 'original_transaction_id', 'receipt']) {
              if (decoded.containsKey(key) && decoded[key] != null) {
                final candidate = decoded[key].toString();
                print('[IAP][DEBUG] found key "$key" => $candidate');
                if (candidate.isNotEmpty) return candidate;
              }
            }
          } else {
            print('[IAP][DEBUG] serverData JSON is not a Map, type=${decoded.runtimeType}');
          }
        } catch (e) {
          print('[IAP][DEBUG] serverData not JSON or jsonDecode failed: $e'); 
        }
      }

      final regex = RegExp(r'(GPA\.[0-9A-Za-z\-\._]+)|([0-9]{8,})|([0-9A-Za-z\-\._]{10,})');
      final match = regex.firstMatch(serverData);
      if (match != null) {
        final found = match.group(0);
        print('[IAP][DEBUG] regex matched id => $found');   
        return found;
      } else {
        print('[IAP][DEBUG] regex did not match any id-like token');
      }
    } catch (e) {
      print('[IAP][WARN] _tryParseIdFromServerData error: $e'); 
    }
    print('[IAP][DEBUG] no id parsed from serverVerificationData');
    return null;
  }
}
