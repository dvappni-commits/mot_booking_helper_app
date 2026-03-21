import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  SubscriptionService._();

  static const String _kPrefSubscribed = 'is_subscribed';

  /// MUST match Play Console Product ID exactly
  static const String kTradeSubscriptionId = 'trade_monthly';

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Simple local flag for UI gating
  static bool isSubscribed = false;

  /// Optional UI notifier (if you use ValueListenableBuilder)
  static final ValueNotifier<bool> subscribed = ValueNotifier<bool>(false);

  static ProductDetails? tradeProduct;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isSubscribed = prefs.getBool(_kPrefSubscribed) ?? false;
    subscribed.value = isSubscribed;

    final available = await _iap.isAvailable();
    if (!available) return;

    // Listen for purchase updates
    _sub ??= _iap.purchaseStream.listen(
          (purchases) async {
        await _handlePurchases(purchases);
      },
      onError: (_) {
        // ignore for now
      },
    );

    // Fetch product details for UI
    tradeProduct = await fetchProduct();

    // Trigger restore (this will feed into purchaseStream)
    await restorePurchases();
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  static Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {
      // ignore
    }
  }

  static Future<ProductDetails?> fetchProduct() async {
    final response = await _iap.queryProductDetails({kTradeSubscriptionId});
    if (response.notFoundIDs.isNotEmpty) return null;
    if (response.productDetails.isEmpty) return null;
    return response.productDetails.first;
  }

  /// Called by your PaywallScreen
  static Future<void> buyTradeMonthly() async {
    final product = tradeProduct ?? await fetchProduct();
    if (product == null) {
      throw Exception(
        'Subscription product not found. Check Play Console Product ID and that the app is installed from Internal Testing via Play Store.',
      );
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    // Subscriptions are purchased via buyNonConsumable in this plugin.
    // Free trial is applied by Google automatically if your offer is active + user eligible.
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    bool foundActive = false;

    for (final p in purchases) {
      // Complete purchases when required
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }

      final okStatus =
          p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored;

      final isOurProduct = p.productID == kTradeSubscriptionId;

      if (okStatus && isOurProduct) {
        foundActive = true;
      }
    }

    await _setSubscribed(foundActive);
  }

  static Future<void> _setSubscribed(bool value) async {
    isSubscribed = value;
    subscribed.value = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefSubscribed, value);
  }
}