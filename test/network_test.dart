import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/network/network_logic.dart';

void main() {
  test('إحصاءات الاستجابة والتذبذب والفقد', () {
    final s = pingStats([10, 20, 30, 20], 5);
    expect(s.min, 10);
    expect(s.max, 30);
    expect(s.avg, 20);
    expect(s.jitter, closeTo((10 + 10 + 10) / 3, 1e-9));
    expect(s.lost, 1);
    expect(s.lossPct, 20);
    final none = pingStats([], 10);
    expect(none.lost, 10);
  });

  test('السرعة بالميجابت', () {
    expect(mbps(1250000, const Duration(seconds: 1)), closeTo(10, 1e-9));
    expect(mbps(100, Duration.zero), 0);
  });

  test('تنظيف العنوان', () {
    expect(normalizeUrl('example.com')?.toString(), 'https://example.com');
    expect(normalizeUrl('http://a.org/x')?.scheme, 'http');
    expect(normalizeUrl('ftp://a.org'), isNull);
    expect(normalizeUrl('كلمة'), isNull);
    expect(normalizeUrl(''), isNull);
  });

  test('أسماء سجلات DNS', () {
    expect(dnsTypeName(1), 'A');
    expect(dnsTypeName(15), 'MX');
    expect(dnsTypeName(999), '999');
    expect(dnsStatusAr(3), 'الاسم غير موجود');
  });
}
