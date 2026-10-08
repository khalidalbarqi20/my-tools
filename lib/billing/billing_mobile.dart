import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'billing_logic.dart';

/// اشتراك «إزالة الإعلانات» عبر Google Play Billing، بدون خادم:
/// نسأل المتجر عند كل تشغيل، ونحتفظ بآخر تحقق ناجح محليًا.
class Billing {
  static const _key = 'adfree_verified_at';
  static final ValueNotifier<bool> adFree = ValueNotifier(false);
  static final ValueNotifier<bool> busy = ValueNotifier(false);
  static final ValueNotifier<String?> message = ValueNotifier(null);

  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static bool _started = false;
  static bool _restoring = false; // الدفعة القادمة نتيجة استعادة
  static bool _announce = false; // المستخدم طلب الاستعادة بنفسه

  static bool get supported => defaultTargetPlatform == TargetPlatform.android;

  /// يحمّل الحالة المحفوظة فورًا، ويتصل بالمتجر في الخلفية.
  static Future<void> init() async {
    if (_started) return;
    _started = true;
    await _loadCache();
    _connect();
  }

  static Future<void> _loadCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final ms = p.getInt(_key);
      final at = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      adFree.value = entitlementActive(at, DateTime.now());
    } catch (_) {}
  }

  static Future<void> _save(DateTime? at) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (at == null) {
        await p.remove(_key);
      } else {
        await p.setInt(_key, at.millisecondsSinceEpoch);
      }
    } catch (_) {}
  }

  static bool _listen() {
    if (_sub != null) return true;
    try {
      _sub = InAppPurchase.instance.purchaseStream
          .listen(_onPurchases, onError: (Object _) => busy.value = false);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _connect() async {
    if (!supported) return;
    try {
      if (!await InAppPurchase.instance.isAvailable()) return;
      if (!_listen()) return;
      _restoring = true;
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      _restoring = false;
    }
  }

  static Future<List<AdFreeOffer>> loadOffers() async {
    if (!supported) return const [];
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) return const [];
      final r = await iap.queryProductDetails(adFreeProductIds);
      return [for (final d in r.productDetails) AdFreeOffer(d.id, d.price, d)];
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> buy(AdFreeOffer offer) async {
    if (!supported) return false;
    try {
      busy.value = true;
      message.value = null;
      _listen();
      final ok = await InAppPurchase.instance.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: offer.raw as ProductDetails));
      if (!ok) busy.value = false;
      return ok;
    } catch (_) {
      busy.value = false;
      message.value = 'تعذّر بدء عملية الشراء. حاول مرة أخرى.';
      return false;
    }
  }

  static Future<void> restore() async {
    if (!supported) return;
    busy.value = true;
    message.value = null;
    try {
      _listen();
      _restoring = true;
      _announce = true;
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      _restoring = false;
      _announce = false;
      busy.value = false;
      message.value = 'تعذّر الاتصال بمتجر Google Play.';
    }
  }

  static Future<void> _onPurchases(List<PurchaseDetails> list) async {
    var entitled = false;
    for (final p in list) {
      if (!adFreeProductIds.contains(p.productID)) continue;
      if (p.status == PurchaseStatus.pending) {
        message.value = 'عملية الدفع قيد المعالجة...';
      } else if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        entitled = true;
      } else if (p.status == PurchaseStatus.error) {
        message.value = 'تعذّر إتمام عملية الشراء. حاول مرة أخرى.';
      }
      // بدون تأكيد (acknowledge) يلغي Google الشراء تلقائيًا بعد 3 أيام.
      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (_) {}
      }
    }
    if (entitled) {
      await _save(DateTime.now());
      adFree.value = true;
      if (_announce) message.value = 'تم تفعيل إزالة الإعلانات. شكرًا لدعمك';
    } else if (_restoring) {
      await _save(null);
      adFree.value = false;
      if (_announce) message.value = 'لا يوجد اشتراك فعّال على حسابك في Google Play';
    }
    _restoring = false;
    _announce = false;
    busy.value = false;
  }
}
