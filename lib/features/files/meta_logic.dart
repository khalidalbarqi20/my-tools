/// حذف البيانات الوصفية (EXIF/XMP/GPS) من صور JPEG و PNG بدون إعادة ضغط الصورة.
library;

import 'dart:typed_data';

class MetaInfo {
  bool found = false, gps = false, xmp = false;
  String? make, model, software, date;
  int orientation = 1;

  String? get device {
    final s = [make, model].where((e) => e != null && e.isNotEmpty).join(' ');
    return s.isEmpty ? null : s;
  }
}

class StripResult {
  final Uint8List bytes;
  final MetaInfo before;
  final String ext; // jpg | png
  const StripResult(this.bytes, this.before, this.ext);
}

int _u16(Uint8List b, int o, bool le) => ByteData.sublistView(b).getUint16(o, le ? Endian.little : Endian.big);
int _u32(Uint8List b, int o, bool le) => ByteData.sublistView(b).getUint32(o, le ? Endian.little : Endian.big);

/// يقرأ جدول TIFF (يبدأ بـ II أو MM) ويملأ [info] من IFD0.
void _parseTiff(Uint8List t, MetaInfo info) {
  if (t.length < 8) return;
  final le = t[0] == 0x49 && t[1] == 0x49;
  if (!le && !(t[0] == 0x4D && t[1] == 0x4D)) return;
  if (_u16(t, 2, le) != 42) return;
  final off = _u32(t, 4, le);
  if (off + 2 > t.length) return;
  final n = _u16(t, off, le);
  for (var i = 0; i < n; i++) {
    final e = off + 2 + 12 * i;
    if (e + 12 > t.length) break;
    final tag = _u16(t, e, le), type = _u16(t, e + 2, le), cnt = _u32(t, e + 4, le);
    if (tag == 0x8825) {
      info.gps = true;
    } else if (tag == 0x0112 && type == 3) {
      info.orientation = _u16(t, e + 8, le);
    } else if ((tag == 0x010F || tag == 0x0110 || tag == 0x0131 || tag == 0x0132) && type == 2) {
      final vo = cnt <= 4 ? e + 8 : _u32(t, e + 8, le);
      if (vo >= 0 && vo + cnt <= t.length) {
        final raw = t.sublist(vo, vo + cnt);
        final z = raw.indexOf(0);
        final s = String.fromCharCodes(z >= 0 ? raw.sublist(0, z) : raw).trim();
        if (tag == 0x010F) info.make = s;
        if (tag == 0x0110) info.model = s;
        if (tag == 0x0131) info.software = s;
        if (tag == 0x0132) info.date = s;
      }
    }
  }
}

bool _startsWith(Uint8List b, int o, List<int> p) {
  if (o + p.length > b.length) return false;
  for (var i = 0; i < p.length; i++) {
    if (b[o + i] != p[i]) return false;
  }
  return true;
}

const _exifTag = [0x45, 0x78, 0x69, 0x66, 0, 0]; // "Exif\0\0"

/// APP1 صغير فيه وسم الاتجاه فقط (حتى لا تنقلب الصورة بعد الحذف).
Uint8List _orientationSegment(int o) {
  final b = BytesBuilder();
  final body = <int>[
    ..._exifTag,
    0x4D, 0x4D, 0x00, 0x2A, 0, 0, 0, 8, // ترويسة TIFF (big endian) و IFD0 عند 8
    0x00, 0x01, // عدد العناصر
    0x01, 0x12, 0x00, 0x03, 0, 0, 0, 1, (o >> 8) & 0xFF, o & 0xFF, 0, 0, // الاتجاه
    0, 0, 0, 0, // لا IFD تالٍ
  ];
  final len = body.length + 2;
  b.add([0xFF, 0xE1, (len >> 8) & 0xFF, len & 0xFF]);
  b.add(body);
  return b.toBytes();
}

StripResult _stripJpeg(Uint8List d) {
  final info = MetaInfo();
  final out = BytesBuilder();
  out.add([0xFF, 0xD8]);
  var i = 2;
  while (i < d.length) {
    if (d[i] != 0xFF) {
      out.add(d.sublist(i));
      break;
    }
    if (i + 1 >= d.length) break;
    final m = d[i + 1];
    if (m == 0xFF) {
      i++;
      continue;
    }
    if (m == 0x01 || (m >= 0xD0 && m <= 0xD7)) {
      out.add(d.sublist(i, i + 2));
      i += 2;
      continue;
    }
    if (m == 0xDA) {
      out.add(d.sublist(i));
      break;
    }
    if (i + 4 > d.length) break;
    final len = _u16(d, i + 2, false);
    final end = i + 2 + len > d.length ? d.length : i + 2 + len;
    var drop = m == 0xE1 || m == 0xED || m == 0xFE || (m >= 0xE3 && m <= 0xEB);
    if (m == 0xE1 && _startsWith(d, i + 4, _exifTag)) {
      _parseTiff(Uint8List.sublistView(d, i + 10, end), info);
      info.found = true;
    } else if (m == 0xE1) {
      info.xmp = true;
      info.found = true;
    } else if (drop) {
      info.found = true;
    }
    if (!drop) out.add(d.sublist(i, end));
    i = end;
  }
  var res = out.toBytes();
  if (info.orientation != 1 && info.orientation >= 2 && info.orientation <= 8) {
    var pos = 2;
    if (res.length > 6 && res[2] == 0xFF && res[3] == 0xE0) pos = 4 + _u16(res, 4, false);
    final b = BytesBuilder()
      ..add(res.sublist(0, pos))
      ..add(_orientationSegment(info.orientation))
      ..add(res.sublist(pos));
    res = b.toBytes();
  }
  return StripResult(res, info, 'jpg');
}

const _pngSig = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const _pngDrop = {'eXIf', 'tEXt', 'zTXt', 'iTXt', 'tIME'};

StripResult _stripPng(Uint8List d) {
  final info = MetaInfo();
  final out = BytesBuilder()..add(d.sublist(0, 8));
  var i = 8;
  while (i + 12 <= d.length) {
    final len = _u32(d, i, false);
    final type = String.fromCharCodes(d.sublist(i + 4, i + 8));
    final end = i + 12 + len;
    if (end > d.length) {
      out.add(d.sublist(i));
      break;
    }
    if (_pngDrop.contains(type)) {
      info.found = true;
      if (type == 'eXIf') _parseTiff(Uint8List.sublistView(d, i + 8, i + 8 + len), info);
    } else {
      out.add(d.sublist(i, end));
    }
    i = end;
    if (type == 'IEND') break;
  }
  return StripResult(out.toBytes(), info, 'png');
}

/// يحذف البيانات الوصفية. يدعم JPEG و PNG فقط، وغيرها يرمي FormatException.
StripResult stripMetadata(Uint8List d) {
  if (d.length > 4 && d[0] == 0xFF && d[1] == 0xD8) return _stripJpeg(d);
  if (_startsWith(d, 0, _pngSig)) return _stripPng(d);
  throw const FormatException('الصيغة غير مدعومة. يدعم JPG و PNG فقط (حوّل الصورة أولًا من أداة تحويل الصور).');
}
