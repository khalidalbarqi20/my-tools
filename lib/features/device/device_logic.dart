import 'dart:math';

/// قطر الشاشة بالبوصة تقريبًا: الإطار المنطقي × نسبة الكثافة، ثم القسمة على كثافة أندرويد (dpr × 160).
double screenInches(double widthPx, double heightPx, double dpr) {
  if (!(widthPx > 0 && heightPx > 0 && dpr > 0)) return 0;
  return sqrt(widthPx * widthPx + heightPx * heightPx) / (dpr * 160);
}

String inchesLabel(double v) =>
    v <= 0 ? 'غير معروف' : '${v.toStringAsFixed(1)} بوصة (تقريبي)';

String androidLabel(String release, int sdk) => 'Android $release (API $sdk)';

String batteryStateAr(String name) {
  switch (name) {
    case 'charging':
      return 'يشحن';
    case 'discharging':
      return 'لا يشحن';
    case 'full':
      return 'ممتلئة';
    case 'connectedNotCharging':
      return 'موصول بدون شحن';
    default:
      return 'غير معروف';
  }
}

String dpiLabel(double dpr) =>
    dpr > 0 ? '${(dpr * 160).round()} dpi (تقريبي)' : 'غير معروف';

/// اتجاه أعلى الجهاز بالدرجات عن الشمال المغناطيسي (0–360)، مع تعويض ميلان الجهاز.
/// المدخلات: قراءة مقياس التسارع (a) ومقياس المغناطيسية (m) بإحداثيات الجهاز.
/// نفس طريقة Android SensorManager.getRotationMatrix. يرجع null لو القراءات غير صالحة.
double? compassHeading(
    double ax, double ay, double az, double mx, double my, double mz) {
  final hx = my * az - mz * ay;
  final hy = mz * ax - mx * az;
  final hz = mx * ay - my * ax;
  final normH = sqrt(hx * hx + hy * hy + hz * hz);
  final normA = sqrt(ax * ax + ay * ay + az * az);
  if (!normH.isFinite || !normA.isFinite || normH < 0.1 || normA < 0.1) {
    return null;
  }
  final nhx = hx / normH, nhy = hy / normH, nhz = hz / normH;
  final nax = ax / normA;
  final naz = az / normA;
  final northY = naz * nhx - nax * nhz;
  final deg = atan2(nhy, northY) * 180 / pi;
  return (deg + 360) % 360;
}

const _dirs = [
  'شمال',
  'شمال شرق',
  'شرق',
  'جنوب شرق',
  'جنوب',
  'جنوب غرب',
  'غرب',
  'شمال غرب',
];

String directionAr(double deg) {
  final d = ((deg % 360) + 360) % 360;
  return _dirs[((d + 22.5) / 45).floor() % 8];
}

/// ميلان الجهاز المسطّح بالدرجات حول المحورين (x, y).
(double, double) levelAngles(double ax, double ay, double az) =>
    (atan2(ax, az) * 180 / pi, atan2(ay, az) * 180 / pi);

/// ملف WAV صغير (16 بت، ستيريو) لنغمة جيبية؛ يُستخدم لاختبار السماعة اليمنى واليسرى.
List<int> toneWav({
  double freq = 440,
  int ms = 1200,
  bool left = true,
  bool right = true,
  int rate = 22050,
}) {
  final n = rate * ms ~/ 1000;
  final dataLen = n * 4;
  final b = List<int>.filled(44 + dataLen, 0);
  void s(int o, String t) {
    for (var i = 0; i < t.length; i++) {
      b[o + i] = t.codeUnitAt(i);
    }
  }

  void u32(int o, int v) {
    for (var i = 0; i < 4; i++) {
      b[o + i] = (v >> (8 * i)) & 0xFF;
    }
  }

  void u16(int o, int v) {
    b[o] = v & 0xFF;
    b[o + 1] = (v >> 8) & 0xFF;
  }

  s(0, 'RIFF');
  u32(4, 36 + dataLen);
  s(8, 'WAVEfmt ');
  u32(16, 16);
  u16(20, 1);
  u16(22, 2);
  u32(24, rate);
  u32(28, rate * 4);
  u16(32, 4);
  u16(34, 16);
  s(36, 'data');
  u32(40, dataLen);
  final fade = rate ~/ 50; // 20ms لتفادي الطقطقة
  for (var i = 0; i < n; i++) {
    var a = sin(2 * pi * freq * i / rate) * 0.6;
    if (i < fade) a *= i / fade;
    if (i > n - fade) a *= (n - i) / fade;
    final v = (a * 32767).round() & 0xFFFF;
    final o = 44 + i * 4;
    if (left) u16(o, v);
    if (right) u16(o + 2, v);
  }
  return b;
}

/// يحوّل مستوى الصوت من ديسيبل (-160..0) إلى 0..1 للعرض.
double micLevel(double db) {
  if (db.isNaN) return 0;
  return ((db + 60) / 60).clamp(0.0, 1.0).toDouble();
}
