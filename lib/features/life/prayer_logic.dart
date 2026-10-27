/// مواقيت الصلاة بحساب فلكي محلي (طريقة أم القرى: الفجر 18.5° والعشاء بعد المغرب بـ 90 دقيقة)
/// واتجاه القبلة. لا تحتاج إنترنت. النتائج تقريبية وقد تختلف دقيقة أو دقيقتين عن التقويم الرسمي.
library;

import 'dart:math' as math;

const _d2r = math.pi / 180;
double _sin(double d) => math.sin(d * _d2r);
double _cos(double d) => math.cos(d * _d2r);
double _tan(double d) => math.tan(d * _d2r);
double _asin(double x) => math.asin(x) / _d2r;
double _acos(double x) => math.acos(x.clamp(-1.0, 1.0)) / _d2r;
double _atan2(double y, double x) => math.atan2(y, x) / _d2r;
double _acot(double x) => math.atan(1 / x) / _d2r;
double _fixA(double a) => a - 360 * (a / 360).floorToDouble();
double _fixH(double h) => h - 24 * (h / 24).floorToDouble();

double _julian(int y, int m, int d) {
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + d + b - 1524.5;
}

class _Sun {
  final double decl, eqt;
  const _Sun(this.decl, this.eqt);
}

_Sun _sunPos(double jd) {
  final d = jd - 2451545.0;
  final g = _fixA(357.529 + 0.98560028 * d);
  final q = _fixA(280.459 + 0.98564736 * d);
  final l = _fixA(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
  final e = 23.439 - 0.00000036 * d;
  final ra = _atan2(_cos(e) * _sin(l), _cos(l)) / 15;
  return _Sun(_asin(_sin(e) * _sin(l)), q / 15 - _fixH(ra));
}

/// أوقات اليوم بالساعات العشرية بتوقيت المنطقة [tz] (مثلًا 3.0 للسعودية).
class PrayerDay {
  final double fajr, sunrise, dhuhr, asr, maghrib, isha;
  const PrayerDay(this.fajr, this.sunrise, this.dhuhr, this.asr, this.maghrib, this.isha);
}

PrayerDay calcPrayer(DateTime date, double lat, double lng, double tz,
    {bool hanafi = false, int ishaMinutes = 90, double fajrAngle = 18.5}) {
  final jd = _julian(date.year, date.month, date.day) - lng / (15 * 24);
  double mid(double t) => _fixH(12 - _sunPos(jd + t).eqt);
  double angleTime(double ang, double t, {bool ccw = false}) {
    final decl = _sunPos(jd + t).decl;
    final n = -_sin(ang) - _sin(decl) * _sin(lat);
    final dd = _cos(decl) * _cos(lat);
    return mid(t) + (ccw ? -1 : 1) * _acos(n / dd) / 15;
  }

  double asr(double f, double t) {
    final decl = _sunPos(jd + t).decl;
    final ang = -_acot(f + _tan((lat - decl).abs()));
    return angleTime(ang, t);
  }

  final fajr = angleTime(fajrAngle, 5 / 24, ccw: true);
  final sunrise = angleTime(0.833, 6 / 24, ccw: true);
  final dhuhr = mid(12 / 24);
  final a = asr(hanafi ? 2 : 1, 13 / 24);
  final sunset = angleTime(0.833, 18 / 24);
  final off = tz - lng / 15;
  final maghrib = sunset + off;
  return PrayerDay(fajr + off, sunrise + off, dhuhr + off + 1 / 60, a + off, maghrib,
      maghrib + ishaMinutes / 60);
}

/// اتجاه القبلة بالدرجات من الشمال مع عقارب الساعة.
double qiblaBearing(double lat, double lng) {
  const kLat = 21.4225, kLng = 39.8262;
  final dl = kLng - lng;
  final y = _sin(dl) * _cos(kLat);
  final x = _cos(lat) * _sin(kLat) - _sin(lat) * _cos(kLat) * _cos(dl);
  return (_atan2(y, x) + 360) % 360;
}

/// يحوّل ساعات عشرية إلى «٠٤:٣٨ ص» (بتقريب لأقرب دقيقة).
String fmtHm(double h, {bool h12 = true}) {
  final total = (_fixH(h) * 60).round() % 1440;
  final hh = total ~/ 60, mm = total % 60;
  final m = mm < 10 ? '0$mm' : '$mm';
  if (!h12) return '${hh < 10 ? '0$hh' : '$hh'}:$m';
  final h12v = hh % 12 == 0 ? 12 : hh % 12;
  return '$h12v:$m ${hh < 12 ? 'ص' : 'م'}';
}

class NextPrayer {
  final String name;
  final Duration left;
  const NextPrayer(this.name, this.left);
}

/// الصلاة القادمة بعد [now] (وقت الجهاز المحلي، ويُفترض أنه بتوقيت المدينة).
NextPrayer nextPrayer(DateTime now, double lat, double lng, double tz,
    {bool hanafi = false}) {
  PrayerDay day(DateTime d) => calcPrayer(d, lat, lng, tz, hanafi: hanafi);
  final today = day(now);
  final nowH = now.hour + now.minute / 60 + now.second / 3600;
  final list = [
    ('الفجر', today.fajr),
    ('الظهر', today.dhuhr),
    ('العصر', today.asr),
    ('المغرب', today.maghrib),
    ('العشاء', today.isha),
  ];
  for (final e in list) {
    if (e.$2 > nowH) {
      return NextPrayer(e.$1, Duration(seconds: ((e.$2 - nowH) * 3600).round()));
    }
  }
  final tomorrow = day(now.add(const Duration(days: 1)));
  return NextPrayer(
      'الفجر', Duration(seconds: ((tomorrow.fajr + 24 - nowH) * 3600).round()));
}

class City {
  final String name;
  final double lat, lng;
  const City(this.name, this.lat, this.lng);
}

const cities = <City>[
  City('الرياض', 24.7136, 46.6753),
  City('مكة المكرمة', 21.4225, 39.8262),
  City('المدينة المنورة', 24.4672, 39.6111),
  City('جدة', 21.4858, 39.1925),
  City('الدمام', 26.4207, 50.0888),
  City('الخبر', 26.2172, 50.1971),
  City('الأحساء', 25.3648, 49.5875),
  City('الطائف', 21.2703, 40.4158),
  City('بريدة', 26.3260, 43.9750),
  City('حائل', 27.5114, 41.7208),
  City('تبوك', 28.3838, 36.5550),
  City('أبها', 18.2164, 42.5053),
  City('بارق', 18.9333, 41.9333),
  City('جازان', 16.8892, 42.5706),
  City('نجران', 17.4933, 44.1277),
  City('الباحة', 20.0129, 41.4677),
  City('سكاكا', 29.9697, 40.2064),
  City('عرعر', 30.9753, 41.0381),
  City('ينبع', 24.0895, 38.0618),
  City('الخرج', 24.1556, 47.3347),
];
