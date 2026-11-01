import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/files/meta_logic.dart';

// صورة JPEG فيها EXIF (جهاز + GPS + اتجاه 6 + برنامج + تاريخ) وتعليق.
const _jpg = '/9j/4AAQSkZJRgABAQAAAQABAAD/4QC+RXhpZgAATU0AKgAAAAgABgEPAAIAAAAGAAAAVgEQAAIAAAAHAAAAXAESAAMAAAABAAYAAAExAAIAAAAHAAAAZAEyAAIAAAAUAAAAbIglAAQAAAABAAAAgAAAAABDYW5vbgBFT1MgNUQAAE15U29mdAAAMjAyNjoxMDoyNyAxMDowMDowMAAAAgABAAIAAAACTgAAAAACAAUAAAADAAAAngAAAAAAAAAYAAAAAQAAACoAAAABAAAAAAAAAAH//gAHaGVsbG//2wBDABALDA4MChAODQ4SERATGCgaGBYWGDEjJR0oOjM9PDkzODdASFxOQERXRTc4UG1RV19iZ2hnPk1xeXBkeFxlZ2P/2wBDARESEhgVGC8aGi9jQjhCY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2P/wAARCAAMABADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBtFFFeWeyf/9k=';
// صورة PNG فيها نصوص (tEXt).
const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAIAAAAmkwkpAAAADXRFWHRBdXRob3IAS2hhbGlk9Vs1DwAAABJ0RVh0Q29tbWVudAB4eHh4eHh4eHh4Ygrx7AAAABRJREFUeJxjZGRiZoABJgYkgJsDAAIuAA4mKvN3AAAAAElFTkSuQmCC';

void main() {
  test('JPEG: يقرأ البيانات ثم يحذفها ويبقي الاتجاه فقط', () {
    final src = base64.decode(_jpg);
    final r = stripMetadata(Uint8List.fromList(src));
    expect(r.ext, 'jpg');
    expect(r.before.found, true);
    expect(r.before.gps, true);
    expect(r.before.make, 'Canon');
    expect(r.before.model, 'EOS 5D');
    expect(r.before.device, 'Canon EOS 5D');
    expect(r.before.software, 'MySoft');
    expect(r.before.date, '2026:10:27 10:00:00');
    expect(r.before.orientation, 6);
    expect(r.bytes.length, lessThan(src.length));
    expect(r.bytes[0], 0xFF);
    expect(r.bytes[1], 0xD8);
    // بعد الحذف: لا GPS ولا جهاز، والاتجاه محفوظ
    final again = stripMetadata(r.bytes);
    expect(again.before.gps, false);
    expect(again.before.make, isNull);
    expect(again.before.orientation, 6);
    expect(String.fromCharCodes(r.bytes).contains('Canon'), false);
    expect(String.fromCharCodes(r.bytes).contains('hello'), false);
  });

  test('PNG: يحذف النصوص ويبقي الصورة', () {
    final src = base64.decode(_png);
    final r = stripMetadata(Uint8List.fromList(src));
    expect(r.ext, 'png');
    expect(r.before.found, true);
    expect(r.bytes.length, lessThan(src.length));
    expect(String.fromCharCodes(r.bytes).contains('Khalid'), false);
    expect(r.bytes.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    expect(stripMetadata(r.bytes).before.found, false);
  });

  test('صيغ غير مدعومة', () {
    expect(() => stripMetadata(Uint8List.fromList([1, 2, 3, 4, 5])), throwsFormatException);
  });
}
