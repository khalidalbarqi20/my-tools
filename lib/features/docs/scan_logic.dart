/// تحسين صور المستندات الممسوحة (دوال نقية على بكسلات RGBA قابلة للاختبار).
library;

import 'dart:math' as math;
import 'dart:typed_data';

enum ScanMode { original, doc, bw, color }

const scanModeNames = {
  ScanMode.original: 'الأصل',
  ScanMode.doc: 'مستند رمادي',
  ScanMode.bw: 'أبيض وأسود',
  ScanMode.color: 'ألوان محسّنة',
};

/// يحسّن الصورة حسب [mode]. يعتمد على متوسط الإضاءة المحلي (صورة تكاملية)
/// فيعادل الظلال وتفاوت الإضاءة، ويجعل الورق أبيض والكتابة داكنة.
Uint8List enhanceDocument(Uint8List rgba, int w, int h, ScanMode mode) {
  if (mode == ScanMode.original) return rgba;
  final n = w * h;
  final g = Float64List(n);
  for (var i = 0; i < n; i++) {
    g[i] = 0.299 * rgba[4 * i] + 0.587 * rgba[4 * i + 1] + 0.114 * rgba[4 * i + 2];
  }
  // صورة تكاملية بحجم (w+1)*(h+1)
  final iw = w + 1;
  final integ = Float64List(iw * (h + 1));
  for (var y = 0; y < h; y++) {
    var row = 0.0;
    for (var x = 0; x < w; x++) {
      row += g[y * w + x];
      integ[(y + 1) * iw + x + 1] = integ[y * iw + x + 1] + row;
    }
  }
  final half = math.max(4, w ~/ 12);
  final out = Uint8List.fromList(rgba);
  for (var y = 0; y < h; y++) {
    final y1 = math.max(y - half, 0), y2 = math.min(y + half, h - 1);
    for (var x = 0; x < w; x++) {
      final x1 = math.max(x - half, 0), x2 = math.min(x + half, w - 1);
      final cnt = (x2 - x1 + 1) * (y2 - y1 + 1);
      final sum = integ[(y2 + 1) * iw + x2 + 1] -
          integ[y1 * iw + x2 + 1] -
          integ[(y2 + 1) * iw + x1] +
          integ[y1 * iw + x1];
      final bg = math.max(sum / cnt, 1.0);
      final i = y * w + x;
      switch (mode) {
        case ScanMode.bw:
          final v = g[i] < bg * 0.85 ? 0 : 255;
          out[4 * i] = v;
          out[4 * i + 1] = v;
          out[4 * i + 2] = v;
        case ScanMode.doc:
          final r = g[i] / bg;
          final v = (((r - 0.55) / 0.40).clamp(0.0, 1.0) * 255).round();
          out[4 * i] = v;
          out[4 * i + 1] = v;
          out[4 * i + 2] = v;
        case ScanMode.color:
          final k = 255 / math.max(bg, 40.0);
          for (var c = 0; c < 3; c++) {
            final v = ((rgba[4 * i + c] * k - 40) * 1.2).clamp(0.0, 255.0);
            out[4 * i + c] = v.round();
          }
        case ScanMode.original:
          break;
      }
    }
  }
  return out;
}

/// تدوير 90° مع عقارب الساعة. يرجع (البكسلات، العرض الجديد، الارتفاع الجديد).
(Uint8List, int, int) rotateRgbaCw(Uint8List rgba, int w, int h) {
  final out = Uint8List(rgba.length);
  final nw = h;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final nx = h - 1 - y, ny = x;
      final s = 4 * (y * w + x), d = 4 * (ny * nw + nx);
      out[d] = rgba[s];
      out[d + 1] = rgba[s + 1];
      out[d + 2] = rgba[s + 2];
      out[d + 3] = rgba[s + 3];
    }
  }
  return (out, nw, w);
}
