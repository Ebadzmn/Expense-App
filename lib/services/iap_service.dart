import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Simple In-App Purchase service to manage subscriptions.
class IapService {
  static const String monthlyId = 'com.mashiur.expenseapp.monthly';
  static const String yearlyId = 'com.mashiur.expenseapp.yearly';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  final ValueNotifier<bool> isAvailable = ValueNotifier(false);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<ProductDetails>> products = ValueNotifier(const []);
  // Notifies when user should be entitled (purchase/restored completed)
  final ValueNotifier<bool> isEntitled = ValueNotifier(false);

  Future<void> init() async {
    isLoading.value = true;
    try {
      final available = await _iap.isAvailable();
      isAvailable.value = available;
      if (!available) {
        error.value = 'Store not available';
        isLoading.value = false;
        return;
      }

      await queryProducts({monthlyId, yearlyId});
      _listenToPurchases();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> queryProducts(Set<String> ids) async {
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      error.value = response.error!.message;
    }
    products.value = response.productDetails;
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP not found: ${response.notFoundIDs}');
    }
  }

  Future<void> buy(ProductDetails product) async {
    try {
      isLoading.value = true;
      error.value = null;
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } on Exception catch (e) {
      // Handle user cancellations or other platform exceptions gracefully
      error.value = e.toString();
      isLoading.value = false;
    }
  }

  void _listenToPurchases() {
    _purchaseSub?.cancel();
    _purchaseSub = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            isLoading.value = true;
            break;
          case PurchaseStatus.error:
            isLoading.value = false;
            error.value = purchase.error?.message ?? 'Purchase error';
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            isLoading.value = false;
            isEntitled.value = true;
            // In production, verify receipts/server-side here.
            // Then deliver entitlement.
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            break;
          default:
            break;
        }
      }
    }, onDone: () {
      isLoading.value = false;
    }, onError: (e) {
      error.value = e.toString();
      isLoading.value = false;
    });
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _purchaseSub?.cancel();
  }
}