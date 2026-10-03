import 'dart:math' as math;
import 'dart:typed_data';

String detectFormat(Uint8List b) {
  bool at(int i, List<int> m) {
    if (b.length < i + m.length) return false;
    for (var k = 0; k < m.length; k++) {
      if (b[i + k] != m[k]) return false;
    }
    return true;
  }

  if (at(0, [0xFF, 0xD8, 0xFF])) return 'JPEG';
  if (at(0, [0x89, 0x50, 0x4E, 0x47])) return 'PNG';
  if (at(0, [0x47, 0x49, 0x46, 0x38])) return 'GIF';
  if (at(0, [0x52, 0x49, 0x46, 0x46]) && at(8, [0x57, 0x45, 0x42, 0x50])) {
    return 'WebP';
  }
  if (at(0, [0x42, 0x4D])) return 'BMP';
  if (at(4, [0x66, 0x74, 0x79, 0x70])) return 'HEIC/HEIF';
  return 'غير معروف';
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

String aspectLabel(int w, int h) {
  if (w <= 0 || h <= 0) return '—';
  final g = _gcd(w, h);
  final a = w ~/ g, b = h ~/ g;
  if (a <= 20 && b <= 20) return '$a:$b';
  return '${(w / h).toStringAsFixed(2)}:1';
}

(int, int) resizeDims(int w, int h, int? tw, int? th, {required bool keep}) {
  if (tw == null && th == null) {
    throw const FormatException('اكتب العرض أو الارتفاع');
  }
  if ((tw != null && tw < 1) || (th != null && th < 1)) {
    throw const FormatException('الأبعاد يجب أن تكون أكبر من صفر');
  }
  int nw, nh;
  if (keep) {
    if (tw != null && th != null) {
      final s = math.min(tw / w, th / h);
      nw = (w * s).round();
      nh = (h * s).round();
    } else if (tw != null) {
      nw = tw;
      nh = (h * tw / w).round();
    } else {
      nh = th!;
      nw = (w * th / h).round();
    }
  } else {
    nw = tw ?? w;
    nh = th ?? h;
  }
  nw = math.max(1, nw);
  nh = math.max(1, nh);
  if (nw > 8000 || nh > 8000) {
    throw const FormatException('الحد الأقصى للبعد الواحد 8000 بكسل');
  }
  if (nw * nh > 36000000) {
    throw const FormatException('الحجم الناتج كبير جدًا (الحد الأقصى 36 ميجابكسل)');
  }
  return (nw, nh);
}

/// (x, y, عرض, ارتفاع) بالبكسل من نسب (يسار، أعلى، يمين، أسفل) بين 0 و 1.
(int, int, int, int) cropRect(
    int w, int h, double l, double t, double r, double b) {
  final x = (w * l).round().clamp(0, w - 1).toInt();
  final y = (h * t).round().clamp(0, h - 1).toInt();
  final x2 = (w * r).round().clamp(x + 1, w).toInt();
  final y2 = (h * b).round().clamp(y + 1, h).toInt();
  return (x, y, x2 - x, y2 - y);
}

/// قص مركزي بنسبة معينة، يرجع (يسار، أعلى، يمين، أسفل) كنسب.
(double, double, double, double) centeredAspect(int w, int h, int rw, int rh) {
  final img = w / h, tgt = rw / rh;
  if ((tgt - img).abs() < 1e-9) return (0.0, 0.0, 1.0, 1.0);
  if (tgt < img) {
    final cw = tgt / img;
    final l = (1 - cw) / 2;
    return (l, 0.0, l + cw, 1.0);
  }
  final ch = img / tgt;
  final t = (1 - ch) / 2;
  return (0.0, t, 1.0, t + ch);
}

class PaletteColor {
  final int r, g, b;
  final double share;
  const PaletteColor(this.r, this.g, this.b, this.share);
  static String _h(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
  String get hex => '#${_h(r)}${_h(g)}${_h(b)}';
}

/// يستخرج الألوان السائدة من بيانات RGBA.
List<PaletteColor> extractPalette(Uint8List rgba, {int count = 6}) {
  final buckets = <int, List<int>>{};
  var total = 0;
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] < 128) continue;
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
    final key = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
    final e = buckets.putIfAbsent(key, () => [0, 0, 0, 0]);
    e[0]++;
    e[1] += r;
    e[2] += g;
    e[3] += b;
    total++;
  }
  if (total == 0) return [];
  final sorted = buckets.values.toList()..sort((a, b) => b[0].compareTo(a[0]));
  final reps = <List<int>>[];
  for (final e in sorted) {
    final r = (e[1] / e[0]).round();
    final g = (e[2] / e[0]).round();
    final b = (e[3] / e[0]).round();
    List<int>? near;
    for (final c in reps) {
      final dr = c[1] - r, dg = c[2] - g, db = c[3] - b;
      if (dr * dr + dg * dg + db * db < 48 * 48) {
        near = c;
        break;
      }
    }
    if (near != null) {
      near[0] += e[0];
    } else {
      reps.add([e[0], r, g, b]);
    }
  }
  reps.sort((a, b) => b[0].compareTo(a[0]));
  return [
    for (final c in reps.take(count)) PaletteColor(c[1], c[2], c[3], c[0] / total)
  ];
}
