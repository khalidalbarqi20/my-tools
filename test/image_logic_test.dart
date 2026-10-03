import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/image/image_logic.dart';

Uint8List px(List<List<int>> cs) => Uint8List.fromList([
      for (final c in cs) ...[c[0], c[1], c[2], c.length > 3 ? c[3] : 255]
    ]);

void main() {
  test('detectFormat', () {
    expect(detectFormat(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'JPEG');
    expect(detectFormat(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0])), 'PNG');
    expect(
        detectFormat(Uint8List.fromList(
            [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50])),
        'WebP');
    expect(detectFormat(Uint8List.fromList([1, 2, 3])), 'غير معروف');
    expect(detectFormat(Uint8List(0)), 'غير معروف');
  });
  test('aspectLabel', () {
    expect(aspectLabel(1920, 1080), '16:9');
    expect(aspectLabel(4000, 3000), '4:3');
    expect(aspectLabel(1000, 1000), '1:1');
    expect(aspectLabel(1234, 567), '2.18:1');
    expect(aspectLabel(0, 10), '—');
  });
  test('resizeDims', () {
    expect(resizeDims(4000, 3000, 800, null, keep: true), (800, 600));
    expect(resizeDims(4000, 3000, null, 600, keep: true), (800, 600));
    expect(resizeDims(4000, 3000, 800, 800, keep: true), (800, 600));
    expect(resizeDims(4000, 3000, 800, 800, keep: false), (800, 800));
    expect(resizeDims(4000, 3000, 800, null, keep: false), (800, 3000));
    expect(() => resizeDims(100, 100, null, null, keep: true), throwsFormatException);
    expect(() => resizeDims(100, 100, 0, null, keep: true), throwsFormatException);
    expect(() => resizeDims(100, 100, 9000, null, keep: true), throwsFormatException);
    expect(() => resizeDims(100, 100, 7000, 7000, keep: false), throwsFormatException);
  });
  test('cropRect', () {
    expect(cropRect(1000, 500, 0, 0, 1, 1), (0, 0, 1000, 500));
    expect(cropRect(1000, 500, 0.1, 0.2, 0.6, 0.8), (100, 100, 500, 300));
    final r = cropRect(10, 10, 0.5, 0.5, 0.5, 0.5);
    expect(r.$3 >= 1 && r.$4 >= 1, true);
  });
  test('centeredAspect', () {
    final a = centeredAspect(4000, 3000, 1, 1);
    expect([a.$1, a.$2, a.$3, a.$4], [0.125, 0.0, 0.875, 1.0]);
    final b = centeredAspect(4000, 3000, 16, 9);
    expect(b.$1, 0.0);
    expect(b.$2, closeTo(0.125, 1e-9));
    expect(b.$4, closeTo(0.875, 1e-9));
    expect(centeredAspect(100, 100, 1, 1), (0.0, 0.0, 1.0, 1.0));
  });
  test('extractPalette', () {
    final red = List.generate(60, (_) => [255, 0, 0]);
    final blue = List.generate(40, (_) => [0, 0, 255]);
    final p = extractPalette(px([...red, ...blue]));
    expect(p.length, 2);
    expect(p[0].hex, '#FF0000');
    expect(p[0].share, closeTo(0.6, 1e-9));
    expect(p[1].hex, '#0000FF');
    expect(extractPalette(px([[10, 10, 10, 0], [20, 20, 20, 10]])), isEmpty);
    expect(extractPalette(Uint8List(0)), isEmpty);
    final near = extractPalette(px([
      ...List.generate(50, (_) => [250, 0, 0]),
      ...List.generate(50, (_) => [255, 5, 0]),
    ]));
    expect(near.length, 1);
    expect(near[0].share, closeTo(1.0, 1e-9));
  });
}
