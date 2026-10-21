import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/image/bg_logic.dart';

void main() {
  test('maskAlpha', () {
    expect(maskAlpha(0.2, true), 0.0);
    expect(maskAlpha(0.8, true), 1.0);
    expect(maskAlpha(0.5, true), closeTo(0.5, 1e-9));
    expect(maskAlpha(0.49, false), 0.0);
    expect(maskAlpha(0.5, false), 1.0);
  });

  test('applyForegroundMask شفاف', () {
    final px = Uint8List.fromList([10, 20, 30, 255, 40, 50, 60, 255]);
    final out = applyForegroundMask(px, 2, 1, const BgMask(2, 1, [1.0, 0.0]),
        soft: false);
    expect(out, [10, 20, 30, 255, 0, 0, 0, 0]);
  });

  test('applyForegroundMask بلون خلفية', () {
    final px = Uint8List.fromList([10, 20, 30, 255, 40, 50, 60, 255]);
    final out = applyForegroundMask(px, 2, 1, const BgMask(2, 1, [1.0, 0.0]),
        soft: false, bg: 0xFFFFFF);
    expect(out, [10, 20, 30, 255, 255, 255, 255, 255]);
  });

  test('تغيير دقة القناع', () {
    final px = Uint8List.fromList(List.filled(16, 200));
    final out =
        applyForegroundMask(px, 2, 2, const BgMask(1, 1, [1.0]), soft: false);
    expect(out, px);
  });

  test('أبعاد غير صالحة', () {
    expect(
        () => applyForegroundMask(
            Uint8List(8), 2, 1, const BgMask(2, 1, [1.0]), soft: false),
        throwsFormatException);
    expect(
        () => applyForegroundMask(
            Uint8List(7), 2, 1, const BgMask(2, 1, [1.0, 1.0]), soft: false),
        throwsFormatException);
  });
}
