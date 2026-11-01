import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/files/md_logic.dart';
import 'package:my_tools/features/files/zip_core.dart';

void main() {
  test('CRC32 بقيم معروفة', () {
    expect(crc32(utf8.encode('123456789')), 0xCBF43926);
    expect(crc32([]), 0);
    expect(crc32(utf8.encode('a')), 0xE8B7BE43);
  });

  test('ZIP: كتابة ثم قراءة (يشمل العربية وملفًا فارغًا)', () async {
    final files = [
      ZipIn('a.txt', Uint8List.fromList(utf8.encode('hello ' * 500))),
      ZipIn('مجلد/ملف.txt', Uint8List.fromList(utf8.encode('نص عربي'))),
      ZipIn('empty.txt', Uint8List(0)),
    ];
    final z = await buildZip(files);
    final es = readZipEntries(z);
    expect(es.map((e) => e.name).toList(), ['a.txt', 'مجلد/ملف.txt', 'empty.txt']);
    for (var i = 0; i < files.length; i++) {
      expect(await readZipEntry(z, es[i]), files[i].bytes);
      expect(es[i].usize, files[i].bytes.length);
    }
    expect(() => readZipEntries(Uint8List.fromList([1, 2, 3])), throwsFormatException);
    expect(() => buildZip([]), throwsFormatException);
    expect(safeFileName('مجلد/ملف.txt'), 'ملف.txt');
    expect(safeFileName('a/b:c.txt'), 'b_c.txt');
  });

  test('Markdown: الكتل', () {
    final b = parseMarkdown('# عنوان\n\nسطر أول\nسطر ثاني\n\n- أ\n- ب\n\n1. ج\n\n> اقتباس\n\n---\n\n```\ncode\n```\n');
    expect(b.map((e) => e.kind).toList(), [
      MdKind.heading, MdKind.paragraph, MdKind.bullet, MdKind.bullet,
      MdKind.numbered, MdKind.quote, MdKind.rule, MdKind.code,
    ]);
    expect(b[0].level, 1);
    expect(b[0].text, 'عنوان');
    expect(b[1].text, 'سطر أول سطر ثاني');
    expect(b[4].number, 1);
    expect(b[7].text, 'code');
  });

  test('Markdown: داخل السطر', () {
    final s = parseInline('نص **عريض** و*مائل* و`كود` و[رابط](http://x.y)');
    expect(s.where((e) => e.bold).single.text, 'عريض');
    expect(s.where((e) => e.italic).single.text, 'مائل');
    expect(s.where((e) => e.code).single.text, 'كود');
    expect(s.where((e) => e.link != null).single.link, 'http://x.y');
    expect(parseInline('بدون تنسيق').single.text, 'بدون تنسيق');
  });
}
