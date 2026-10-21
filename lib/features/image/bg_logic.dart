import 'dart:typed_data';

/// قناع الثقة الناتج من النموذج: لكل بكسل قيمة 0..1 (1 = العنصر الرئيسي).
class BgMask {
  final int width, height;
  final List<double> conf;
  const BgMask(this.width, this.height, this.conf);
}

/// يحوّل ثقة النموذج إلى شفافية 0..1. الناعمة تلين الحواف، والحادة قص مباشر.
double maskAlpha(double c, bool soft) {
  if (!soft) return c >= 0.5 ? 1.0 : 0.0;
  const lo = 0.3, hi = 0.7;
  if (c <= lo) return 0.0;
  if (c >= hi) return 1.0;
  final t = (c - lo) / (hi - lo);
  return t * t * (3 - 2 * t);
}

double _sample(BgMask m, int x, int y, int w, int h) {
  if (m.width == w && m.height == h) return m.conf[y * w + x];
  final fx = ((x + 0.5) * m.width / w - 0.5).clamp(0.0, m.width - 1.0).toDouble();
  final fy = ((y + 0.5) * m.height / h - 0.5).clamp(0.0, m.height - 1.0).toDouble();
  final x0 = fx.floor(), y0 = fy.floor();
  final x1 = x0 + 1 < m.width ? x0 + 1 : x0;
  final y1 = y0 + 1 < m.height ? y0 + 1 : y0;
  final tx = fx - x0, ty = fy - y0;
  final a = m.conf[y0 * m.width + x0] * (1 - tx) + m.conf[y0 * m.width + x1] * tx;
  final b = m.conf[y1 * m.width + x0] * (1 - tx) + m.conf[y1 * m.width + x1] * tx;
  return a * (1 - ty) + b * ty;
}

/// يطبّق القناع على بكسلات RGBA (premultiplied كما يعطيها Flutter).
/// bg == null: خلفية شفافة. وإلا لون 0xRRGGBB تُملأ به الخلفية (ناتج معتم).
Uint8List applyForegroundMask(Uint8List rgba, int w, int h, BgMask m,
    {bool soft = true, int? bg}) {
  if (w <= 0 || h <= 0 || rgba.length != w * h * 4) {
    throw const FormatException('تعذر قراءة بكسلات الصورة.');
  }
  if (m.width <= 0 || m.height <= 0 || m.conf.length != m.width * m.height) {
    throw const FormatException('نتيجة تحليل الصورة غير صالحة.');
  }
  final out = Uint8List(rgba.length);
  final br = bg == null ? 0 : (bg >> 16) & 255;
  final bgc = bg == null ? 0 : (bg >> 8) & 255;
  final bb = bg == null ? 0 : bg & 255;
  var i = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final a = maskAlpha(_sample(m, x, y, w, h), soft);
      if (bg == null) {
        out[i] = (rgba[i] * a).round();
        out[i + 1] = (rgba[i + 1] * a).round();
        out[i + 2] = (rgba[i + 2] * a).round();
        out[i + 3] = (rgba[i + 3] * a).round();
      } else {
        final cov = a * rgba[i + 3] / 255;
        out[i] = (rgba[i] * a + br * (1 - cov)).round().clamp(0, 255).toInt();
        out[i + 1] = (rgba[i + 1] * a + bgc * (1 - cov)).round().clamp(0, 255).toInt();
        out[i + 2] = (rgba[i + 2] * a + bb * (1 - cov)).round().clamp(0, 255).toInt();
        out[i + 3] = 255;
      }
      i += 4;
    }
  }
  return out;
}
