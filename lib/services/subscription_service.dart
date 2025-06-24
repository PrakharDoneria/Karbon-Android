import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  static const String _subId = 'karbon_monthly_199';
  static const String _subscribedKey = 'is_subscribed';

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _sub;

  bool available = false;
  bool isSubscribed = false;

  /// Call this at app launch
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isSubscribed = prefs.getBool(_subscribedKey) ?? false;

    available = await _iap.isAvailable();
    if (!available) return;

    _sub = _iap.purchaseStream.listen(_onPurchaseUpdated, onDone: () {
      _sub.cancel();
    }, onError: (_) {});

    await _iap.restorePurchases();

    if (Platform.isAndroid) {
      final androidAddition =
      _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final resp = await androidAddition.queryPastPurchases();
      _updateSubscriptionStatus(resp.pastPurchases.map((p) => p.productID));
    }
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (var p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        if (p.productID == _subId) {
          await setSubscribed(true);
        }
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> purchase() async {
    final pdResp = await _iap.queryProductDetails({_subId});
    if (pdResp.notFoundIDs.isNotEmpty) throw 'Subscription not found';
    final product = pdResp.productDetails.first;
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  void _updateSubscriptionStatus(Iterable<String> productIds) async {
    if (productIds.contains(_subId)) {
      await setSubscribed(true);
    }
  }

  Future<void> setSubscribed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscribedKey, value);
    isSubscribed = value;
  }

  void dispose() {
    _sub.cancel();
  }
}
