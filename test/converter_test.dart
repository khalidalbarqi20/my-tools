import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/core/fmt.dart';
import 'package:my_tools/features/converters/converter_logic.dart';

double c(double v, List<Unit> l, int a, int b) => convert(v, l[a], l[b]);

void main() {
  test('الطول', () {
    expect(c(1, lengthUnits, 4, 3), closeTo(1.609344, 1e-9));
    expect(c(1, lengthUnits, 6, 1), closeTo(2.54, 1e-9));
    expect(c(1, lengthUnits, 3, 0), closeTo(1000, 1e-9));
  });
  test('الوزن والمساحة والحجم', () {
    expect(c(1, weightUnits, 2, 1), closeTo(453.59237, 1e-6));
    expect(c(1, areaUnits, 4, 0), closeTo(4046.8564224, 1e-6));
    expect(c(1, volumeUnits, 3, 0), closeTo(1000, 1e-9));
  });
  test('الحرارة', () {
    expect(c(100, tempUnits, 0, 1), closeTo(212, 1e-9));
    expect(c(-40, tempUnits, 1, 0), closeTo(-40, 1e-9));
    expect(c(0, tempUnits, 0, 2), closeTo(273.15, 1e-9));
    expect(c(273.15, tempUnits, 2, 0), closeTo(0, 1e-9));
  });
  test('السرعة والضغط والطاقة', () {
    expect(c(1, speedUnits, 3, 1), closeTo(1.852, 1e-9));
    expect(c(1, speedUnits, 2, 1), closeTo(1.609344, 1e-6));
    expect(c(1, pressureUnits, 2, 1), closeTo(0.0689476, 1e-6));
    expect(c(1, pressureUnits, 3, 0), closeTo(101325, 1e-6));
    expect(c(1, energyUnits, 1, 3), closeTo(860.42, 0.01));
  });
  test('البيانات والوقت', () {
    expect(c(1, dataUnits, 4, 3), closeTo(1024, 1e-9));
    expect(c(8, dataUnits, 0, 1), closeTo(1, 1e-9));
    expect(c(1, timeUnits, 3, 2), closeTo(24, 1e-9));
    expect(c(1, timeUnits, 4, 3), closeTo(7, 1e-9));
  });
  test('ذهاب وإياب بدون خسارة', () {
    for (final l in [lengthUnits, weightUnits, areaUnits, volumeUnits, tempUnits,
        speedUnits, pressureUnits, energyUnits, dataUnits, timeUnits]) {
      for (var i = 0; i < l.length; i++) {
        for (var j = 0; j < l.length; j++) {
          final back = convert(convert(123.456, l[i], l[j]), l[j], l[i]);
          expect(back, closeTo(123.456, 1e-6), reason: '${l[i].name}->${l[j].name}');
        }
      }
    }
  });
  test('fmtSig', () {
    expect(fmtSig(0), '0');
    expect(fmtSig(0.1 + 0.2), '0.3');
    expect(fmtSig(1609.344), '1609.344');
    expect(fmtSig(100000), '100000');
    expect(fmtSig(-40), '-40');
    expect(fmtSig(2.54), '2.54');
    expect(fmtSig(c(1, dataUnits, 0, 5)), contains('e-13'));
    expect(fmtSig(1e20), contains('e+20'));
  });
}
