/// معرّف الاشتراك في Google Play Console (Subscriptions). لازم يطابق ما تنشئه هناك.
const adFreeProductIds = <String>{'remove_ads'};

/// إذا تعذّر الاتصال بالمتجر نثق بآخر تحقق ناجح لمدة محددة ثم نعود للإعلانات.
const entitlementGrace = Duration(days: 14);

bool entitlementActive(DateTime? verifiedAt, DateTime now,
    {Duration grace = entitlementGrace}) {
  if (verifiedAt == null) return false;
  final age = now.difference(verifiedAt);
  return !age.isNegative && age <= grace;
}

/// عرض اشتراك جاهز للعرض في الواجهة (بدون الاعتماد على مكتبة الدفع).
class AdFreeOffer {
  final String id, price;
  final Object raw;
  const AdFreeOffer(this.id, this.price, this.raw);
}
