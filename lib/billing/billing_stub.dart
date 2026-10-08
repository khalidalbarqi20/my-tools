import 'package:flutter/foundation.dart';
import 'billing_logic.dart';

/// نسخة الويب: لا اشتراكات.
class Billing {
  static final ValueNotifier<bool> adFree = ValueNotifier(false);
  static final ValueNotifier<bool> busy = ValueNotifier(false);
  static final ValueNotifier<String?> message = ValueNotifier(null);
  static bool get supported => false;
  static Future<void> init() async {}
  static Future<List<AdFreeOffer>> loadOffers() async => const [];
  static Future<bool> buy(AdFreeOffer offer) async => false;
  static Future<void> restore() async {}
}
