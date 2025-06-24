import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/subscription_service.dart'; // ✅ FIX: Add this line

class PurchaseHandler {
  static final PurchaseHandler instance = PurchaseHandler._internal();
  final InAppPurchase _iap = InAppPurchase.instance;

  final String _subscriptionId = 'karbon_monthly_199';

  PurchaseHandler._internal();

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    await _iap.restorePurchases();
  }

  Future<ProductDetails?> getSubscriptionDetails() async {
    final response = await _iap.queryProductDetails({_subscriptionId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return null;
    }
    return response.productDetails.first;
  }

  Future<void> buySubscription(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void listenToPurchases(Stream<List<PurchaseDetails>> stream) {
    stream.listen((purchases) {
      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          // Optional: validate purchase from backend
          SubscriptionService.instance.setSubscribed(true); // ✅ Works now
        }
      }
    });
  }
}
