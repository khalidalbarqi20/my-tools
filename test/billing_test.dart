import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/billing/billing_logic.dart';

void main() {
  final now = DateTime(2026, 10, 6, 12);
  test('صلاحية الاشتراك المحفوظ', () {
    expect(entitlementActive(null, now), false);
    expect(entitlementActive(now, now), true);
    expect(entitlementActive(now.subtract(const Duration(days: 1)), now), true);
    expect(entitlementActive(now.subtract(const Duration(days: 14)), now), true);
    expect(entitlementActive(now.subtract(const Duration(days: 15)), now), false);
    // ساعة الجهاز رُجعت للخلف: لا نثق بالقيمة
    expect(entitlementActive(now.add(const Duration(days: 1)), now), false);
    expect(entitlementActive(now.subtract(const Duration(days: 20)), now,
        grace: const Duration(days: 30)), true);
  });
  test('معرّف الاشتراك', () {
    expect(adFreeProductIds, {'remove_ads'});
  });
}
