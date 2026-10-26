import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class _Ent {
  final String name;
  final int method, size, off;
  const _Ent(this.name, this.method, this.size, this.off);
}

/// يفك ملف ZIP داخل [dest] (يحذف المجلد الجذري المشترك إن وُجد) ويرجع مسار صفحة البداية.
Future<String> extractZip(File zip, Directory dest) async {
  final b = await zip.readAsBytes();
  final bd = ByteData.sublistView(b);
  int u16(int o) => bd.getUint16(o, Endian.little);
  int u32(int o) => bd.getUint32(o, Endian.little);

  var e = b.length - 22;
  while (e >= 0 && u32(e) != 0x06054b50) {
    e--;
  }
  if (e < 0) throw const FormatException('ملف ZIP غير صالح');
  final total = u16(e + 10);
  var p = u32(e + 16);

  final ents = <_Ent>[];
  for (var i = 0; i < total; i++) {
    if (p + 46 > b.length || u32(p) != 0x02014b50) break;
    final method = u16(p + 10);
    final csize = u32(p + 20);
    final nlen = u16(p + 28), xlen = u16(p + 30), clen = u16(p + 32);
    final off = u32(p + 42);
    final name = utf8
        .decode(b.sublist(p + 46, p + 46 + nlen), allowMalformed: true)
        .replaceAll('\\', '/');
    p += 46 + nlen + xlen + clen;
    if (name.endsWith('/')) continue;
    final parts = name.split('/');
    if (parts.any((s) => s.isEmpty || s == '.' || s == '..')) continue;
    ents.add(_Ent(name, method, csize, off));
  }
  if (ents.isEmpty) throw const FormatException('ملف ZIP فارغ');

  // مجلد جذري واحد يضم كل شيء؟ نزيله.
  var strip = 0;
  final first = ents.first.name.split('/').first;
  if (ents.every((x) => x.name.contains('/') && x.name.split('/').first == first)) {
    strip = first.length + 1;
  }

  final rels = <String>[];
  for (final x in ents) {
    final rel = x.name.substring(strip);
    final ls = x.off + 26;
    final start = x.off + 30 + u16(ls) + u16(ls + 2);
    final raw = Uint8List.sublistView(b, start, start + x.size);
    List<int> data;
    if (x.method == 0) {
      data = raw;
    } else if (x.method == 8) {
      data = ZLibCodec(raw: true).decode(raw);
    } else {
      continue;
    }
    final f = File('${dest.path}/$rel');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(data, flush: false);
    rels.add(rel);
  }

  final htmls = [
    for (final r in rels)
      if (r.toLowerCase().endsWith('.html') || r.toLowerCase().endsWith('.htm')) r
  ];
  if (htmls.isEmpty) throw const FormatException('لا يوجد ملف HTML داخل ZIP.');
  if (htmls.contains('index.html')) return 'index.html';
  htmls.sort((a, c) {
    final d = a.split('/').length - c.split('/').length;
    return d != 0 ? d : a.length - c.length;
  });
  return htmls.first;
}
