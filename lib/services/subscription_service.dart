import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  SubscriptionService._();

  static const String _kPrefSubscribed = 'is_subscribed';

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
    debugPrint('IAP available: $available');

    if (!available) {
      tradeProduct = null;
      return;
    }

    _sub ??= _iap.purchaseStream.listen(
          (purchases) async {
        await _handlePurchases(purchases);
      },
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
      onDone: () {
        debugPrint('Purchase stream closed');
      },
    );

    tradeProduct = await fetchProduct();

    // Do not auto-restore during startup while debugging App Review / TestFlight
    // because it can hide the real product-loading issue.
    // Call restorePurchases() only when the user taps "Restore purchase".
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  static Future<void> restorePurchases() async {
    try {
      debugPrint('Restoring purchases...');
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases failed: $e');
      rethrow;
    }
  }

  static Future<ProductDetails?> fetchProduct() async {
    final available = await _iap.isAvailable();
    debugPrint('fetchProduct -> store available: $available');
    debugPrint('fetchProduct -> product id: $kTradeSubscriptionId');
    debugPrint('fetchProduct -> platform: ${Platform.operatingSystem}');

    if (!available) {
      debugPrint('Store is not available');
      return null;
    }

    final ProductDetailsResponse response =
    await _iap.queryProductDetails({kTradeSubscriptionId});

    debugPrint(
      'fetchProduct -> productDetails count: ${response.productDetails.length}',
    );
    debugPrint('fetchProduct -> notFoundIDs: ${response.notFoundIDs}');
    debugPrint('fetchProduct -> error: ${response.error}');

    if (response.error != null) {
      throw Exception(
        'Store query failed: ${response.error!.message}',
      );
    }

    if (response.notFoundIDs.isNotEmpty) {
      return null;
    }

    if (response.productDetails.isEmpty) {
      return null;
    }

    final product = response.productDetails.first;
    debugPrint(
      'fetchProduct -> found product: ${product.id} | ${product.title} | ${product.price}',
    );

    return product;
  }

  static Future<void> buyTradeMonthly() async {
    final product = tradeProduct ?? await fetchProduct();

    if (product == null) {
      throw Exception(
        Platform.isIOS
            ? 'Subscription product not found. Check that the Product ID matches App Store Connect exactly, the subscription is attached to the app version, and the app is installed from TestFlight.'
            : 'Subscription product not found. Check that the Product ID matches Google Play Console exactly and that the app is installed from Internal Testing via Play Store.',
      );
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    debugPrint('Starting purchase for ${product.id}');
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Future<void> _handlePurchases(
      List<PurchaseDetails> purchases,
      ) async {
    bool foundActive = false;

    for (final p in purchases) {
      debugPrint(
        'Purchase update -> product: ${p.productID}, status: ${p.status}',
      );

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

    debugPrint('Subscription state updated: $value');
  }
}