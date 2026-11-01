import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/files/barcode_logic.dart';

void main() {
  test('Code 128 مطابق لمرجع reportlab', () {
    expect(code128Codes('Hello123'), [104, 40, 69, 76, 76, 79, 17, 18, 19, 44, 106]);
    expect(code128Codes('ABC-123'), [104, 33, 34, 35, 13, 17, 18, 19, 70, 106]);
    expect(code128Codes('12345678'), [105, 12, 34, 56, 78, 47, 106]);
    expect(code128Codes('0012'), [105, 0, 12, 26, 106]);
    expect(code128Bits('Hello123'),
        '110100100001100010100010110010000110010100001100101000010001111010100111001101100111001011001011100100011011101100011101011');
    expect(code128Bits('12345678').length, 79);
  });

  test('EAN-13 و EAN-8', () {
    expect(eanCheckDigit('400638133393'), 1);
    expect(eanCheckDigit('590123412345'), 7);
    expect(eanCheckDigit('9638507'), 4);
    final a = buildBarcode(BarcodeKind.ean13, '400638133393');
    expect(a.label, '4006381333931');
    expect(a.bits,
        '10100011010100111010111101111010001001011001101010100001010000101000010111010010000101100110101');
    expect(buildBarcode(BarcodeKind.ean13, '4006381333931').bits, a.bits);
    final b = buildBarcode(BarcodeKind.ean8, '9638507');
    expect(b.label, '96385074');
    expect(b.bits, '1010001011010111101111010110111010101001110111001010001001011100101');
  });

  test('أخطاء الإدخال', () {
    expect(() => buildBarcode(BarcodeKind.ean13, '4006381333930'), throwsFormatException);
    expect(() => buildBarcode(BarcodeKind.ean13, '123'), throwsFormatException);
    expect(() => buildBarcode(BarcodeKind.ean8, 'abc'), throwsFormatException);
    expect(() => code128Codes('مرحبا'), throwsFormatException);
    expect(() => code128Codes(''), throwsFormatException);
    expect(() => code128Codes('a' * 81), throwsFormatException);
  });
}
