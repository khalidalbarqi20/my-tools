/// قراءة وكتابة ملفات ZIP (بدون ZIP64) في الذاكرة. يعمل على كل المنصات.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'zip_codec.dart';

final _crcTable = () {
  final t = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    t[n] = c;
  }
  return t;
}();

int crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >>> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

class ZipIn {
  final String name;
  final Uint8List bytes;
  const ZipIn(this.name, this.bytes);
}

void _w16(BytesBuilder b, int v) => b.add([v & 0xFF, (v >> 8) & 0xFF]);
void _w32(BytesBuilder b, int v) =>
    b.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >>> 24) & 0xFF]);

/// يبني ZIP. أسماء الملفات بترميز UTF-8 (تظهر العربية صحيحة).
Future<Uint8List> buildZip(List<ZipIn> files) async {
  if (files.isEmpty) throw const FormatException('اختر ملفًا واحدًا على الأقل');
  if (files.length > 65000) throw const FormatException('عدد الملفات كبير');
  final now = DateTime.now();
  final dtime = (now.hour << 11) | (now.minute << 5) | (now.second ~/ 2);
  final ddate = ((now.year - 1980).clamp(0, 127) << 9) | (now.month << 5) | now.day;
  final out = BytesBuilder();
  final cd = BytesBuilder();
  var total = 0;
  for (final f in files) {
    final nb = utf8.encode(f.name);
    final crc = crc32(f.bytes);
    var method = 0;
    var payload = f.bytes;
    if (f.bytes.isNotEmpty) {
      final comp = await deflateRaw(f.bytes);
      if (comp.length < f.bytes.length) {
        method = 8;
        payload = comp;
      }
    }
    final off = out.length;
    if (off > 0xFFFFFFF0 || payload.length > 0xFFFFFFF0) {
      throw const FormatException('الحجم كبير جدًا لملف ZIP عادي (الحد 4 جيجابايت)');
    }
    _w32(out, 0x04034b50);
    _w16(out, 20);
    _w16(out, 0x0800);
    _w16(out, method);
    _w16(out, dtime);
    _w16(out, ddate);
    _w32(out, crc);
    _w32(out, payload.length);
    _w32(out, f.bytes.length);
    _w16(out, nb.length);
    _w16(out, 0);
    out.add(nb);
    out.add(payload);

    _w32(cd, 0x02014b50);
    _w16(cd, 20);
    _w16(cd, 20);
    _w16(cd, 0x0800);
    _w16(cd, method);
    _w16(cd, dtime);
    _w16(cd, ddate);
    _w32(cd, crc);
    _w32(cd, payload.length);
    _w32(cd, f.bytes.length);
    _w16(cd, nb.length);
    _w16(cd, 0);
    _w16(cd, 0);
    _w16(cd, 0);
    _w16(cd, 0);
    _w32(cd, 0);
    _w32(cd, off);
    cd.add(nb);
    total++;
  }
  final cdOff = out.length;
  final cdBytes = cd.toBytes();
  out.add(cdBytes);
  _w32(out, 0x06054b50);
  _w16(out, 0);
  _w16(out, 0);
  _w16(out, total);
  _w16(out, total);
  _w32(out, cdBytes.length);
  _w32(out, cdOff);
  _w16(out, 0);
  return out.toBytes();
}

class ZipEntry {
  final String name;
  final int method, csize, usize, offset;
  final bool encrypted;
  const ZipEntry(this.name, this.method, this.csize, this.usize, this.offset, this.encrypted);
  bool get isDir => name.endsWith('/');
}

List<ZipEntry> readZipEntries(Uint8List b) {
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
  final res = <ZipEntry>[];
  for (var i = 0; i < total; i++) {
    if (p + 46 > b.length || u32(p) != 0x02014b50) break;
    final flags = u16(p + 8), method = u16(p + 10);
    final csize = u32(p + 20), usize = u32(p + 24);
    final nl = u16(p + 28), xl = u16(p + 30), cl = u16(p + 32);
    final off = u32(p + 42);
    final name = utf8.decode(b.sublist(p + 46, p + 46 + nl), allowMalformed: true).replaceAll('\\', '/');
    p += 46 + nl + xl + cl;
    res.add(ZipEntry(name, method, csize, usize, off, (flags & 1) != 0));
  }
  return res;
}

Future<Uint8List> readZipEntry(Uint8List b, ZipEntry e) async {
  if (e.encrypted) throw const FormatException('الملف مشفّر بكلمة سر وغير مدعوم');
  final bd = ByteData.sublistView(b);
  final ln = bd.getUint16(e.offset + 26, Endian.little);
  final lx = bd.getUint16(e.offset + 28, Endian.little);
  final start = e.offset + 30 + ln + lx;
  if (start + e.csize > b.length) throw const FormatException('ملف ZIP تالف');
  final raw = Uint8List.sublistView(b, start, start + e.csize);
  if (e.method == 0) return raw;
  if (e.method == 8) return inflateRaw(raw);
  throw const FormatException('طريقة ضغط غير مدعومة');
}

/// اسم آمن للحفظ: بدون مسار ولا أحرف خطرة.
String safeFileName(String path) {
  final n = path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? 'file';
  final c = n.replaceAll(RegExp(r'[\\:*?"<>|]'), '_');
  return c.isEmpty ? 'file' : c;
}
