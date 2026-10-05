import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/device/device_logic.dart';

void main() {
  compassTests();
  test('حجم الشاشة بالبوصة', () {
    expect(screenInches(1080, 2400, 2.625), closeTo(6.27, 0.01));
    expect(screenInches(0, 2400, 2.625), 0);
    expect(screenInches(1080, 2400, 0), 0);
    expect(screenInches(-1, 5, 2), 0);
  });
  test('النصوص', () {
    expect(inchesLabel(0), 'غير معروف');
    expect(inchesLabel(6.266), '6.3 بوصة (تقريبي)');
    expect(androidLabel('14', 34), 'Android 14 (API 34)');
    expect(dpiLabel(2.625), '420 dpi (تقريبي)');
    expect(dpiLabel(0), 'غير معروف');
  });
  test('حالة البطارية', () {
    expect(batteryStateAr('charging'), 'يشحن');
    expect(batteryStateAr('full'), 'ممتلئة');
    expect(batteryStateAr('discharging'), 'لا يشحن');
    expect(batteryStateAr('xyz'), 'غير معروف');
  });
}

void compassTests() {
  double diff(double a, double b) => ((a - b + 540) % 360) - 180;
  group('البوصلة', () {
    const g = 9.8;
    test('الجهاز مسطح واتجاهه للشمال/الشرق/الجنوب/الغرب', () {
      expect(diff(compassHeading(0, 0, g, 0, 20, -40)!, 0), closeTo(0, 1e-6));
      expect(diff(compassHeading(0, 0, g, -20, 0, -40)!, 90), closeTo(0, 1e-6));
      expect(diff(compassHeading(0, 0, g, 0, -20, -40)!, 180), closeTo(0, 1e-6));
      expect(diff(compassHeading(0, 0, g, 20, 0, -40)!, 270), closeTo(0, 1e-6));
    });
    test('تعويض الميلان 30 درجة', () {
      final s = sin(30 * pi / 180), c = cos(30 * pi / 180);
      final my = 20 * c - 40 * s;
      final mz = -20 * s - 40 * c;
      final h = compassHeading(0, g * s, g * c, 0, my, mz)!;
      expect(diff(h, 0), closeTo(0, 1e-6));
    });
    test('قراءات غير صالحة', () {
      expect(compassHeading(0, 0, 0, 0, 20, -40), isNull);
      expect(compassHeading(0, 0, g, 0, 0, 0), isNull);
      expect(compassHeading(double.nan, 0, g, 0, 20, -40), isNull);
    });
    test('أسماء الاتجاهات', () {
      expect(directionAr(0), 'شمال');
      expect(directionAr(45), 'شمال شرق');
      expect(directionAr(90), 'شرق');
      expect(directionAr(180), 'جنوب');
      expect(directionAr(270), 'غرب');
      expect(directionAr(359), 'شمال');
      expect(directionAr(22.4), 'شمال');
      expect(directionAr(22.6), 'شمال شرق');
      expect(directionAr(-90), 'غرب');
    });
    test('زوايا الميزان', () {
      final (x0, y0) = levelAngles(0, 0, g);
      expect(x0, 0);
      expect(y0, 0);
      final (x1, y1) = levelAngles(g * sin(30 * pi / 180), 0, g * cos(30 * pi / 180));
      expect(x1, closeTo(30, 1e-6));
      expect(y1, closeTo(0, 1e-6));
    });
  });
}
