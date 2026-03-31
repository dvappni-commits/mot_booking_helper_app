import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  SubscriptionService._();

  static const String _kPrefSubscribed = 'is_subscribed';

  // Product IDs must match the store exactly
  static const String _kAndroidSubscriptionId = 'trade_monthly';
  static const String _kiOSSubscriptionId = 'mot_premium_monthly';

  static String get kTradeSubscriptionId =>
      Platform.isIOS ? _kiOSSubscriptionId : _kAndroidSubscriptionId;

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;

  static bool isSubscribed = false;
  static final ValueNotifier<bool> subscribed = ValueNotifier<bool>(false);

  static ProductDetails? tradeProduct;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isSubscribed = prefs.getBool(_kPrefSubscribed) ?? false;
    subscribed.value = isSubscribed;

    final available = await _iap.isAvailable();
    if (!available) return;

    _sub ??= _iap.purchaseStream.listen(
          (purchases) async {
        await _handlePurchases(purchases);
      },
      onError: (_) {
        // ignore for now
      },
    );

    tradeProduct = await fetchProduct();
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

  static Future<void> buyTradeMonthly() async {
    final product = tradeProduct ?? await fetchProduct();
    if (product == null) {
      throw Exception(
        Platform.isIOS
            ? 'Subscription product not found. Check that the Product ID matches App Store Connect exactly and that the app is installed from TestFlight.'
            : 'Subscription product not found. Check that the Product ID matches Google Play Console exactly and that the app is installed from Internal Testing via Play Store.',
      );
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    bool foundActive = false;

    for (final p in purchases) {
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }

      final okStatus =
          p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored;

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