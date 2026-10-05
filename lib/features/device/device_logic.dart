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
