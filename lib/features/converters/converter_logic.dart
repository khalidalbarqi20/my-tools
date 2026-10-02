class Unit {
  final String name;
  final double Function(double) toBase;
  final double Function(double) fromBase;
  Unit._(this.name, this.toBase, this.fromBase);
  factory Unit(String name, double f) =>
      Unit._(name, (v) => v * f, (v) => v / f);
  factory Unit.custom(String name, double Function(double) to,
          double Function(double) from) =>
      Unit._(name, to, from);
}

double convert(double v, Unit a, Unit b) => b.fromBase(a.toBase(v));

final lengthUnits = [
  Unit('متر (m)', 1),
  Unit('سنتيمتر (cm)', 0.01),
  Unit('مليمتر (mm)', 0.001),
  Unit('كيلومتر (km)', 1000),
  Unit('ميل (mi)', 1609.344),
  Unit('قدم (ft)', 0.3048),
  Unit('بوصة (in)', 0.0254),
  Unit('ياردة (yd)', 0.9144),
];

final weightUnits = [
  Unit('كيلوجرام (kg)', 1),
  Unit('جرام (g)', 0.001),
  Unit('رطل (lb)', 0.45359237),
  Unit('أونصة (oz)', 0.028349523125),
  Unit('طن (t)', 1000),
];

final areaUnits = [
  Unit('متر مربع (m²)', 1),
  Unit('قدم مربع (ft²)', 0.09290304),
  Unit('كيلومتر مربع (km²)', 1e6),
  Unit('هكتار (ha)', 1e4),
  Unit('أكر (acre)', 4046.8564224),
  Unit('فدان مصري', 4200.833),
];

final volumeUnits = [
  Unit('لتر (L)', 1),
  Unit('مليلتر (mL)', 0.001),
  Unit('جالون أمريكي (gal)', 3.785411784),
  Unit('متر مكعب (m³)', 1000),
  Unit('قدم مكعب (ft³)', 28.316846592),
];

final tempUnits = [
  Unit.custom('سلزيوس (°C)', (v) => v, (v) => v),
  Unit.custom('فهرنهايت (°F)', (v) => (v - 32) * 5 / 9, (v) => v * 9 / 5 + 32),
  Unit.custom('كلفن (K)', (v) => v - 273.15, (v) => v + 273.15),
];

final speedUnits = [
  Unit('متر/ثانية (m/s)', 1),
  Unit('كم/ساعة (km/h)', 1 / 3.6),
  Unit('ميل/ساعة (mph)', 0.44704),
  Unit('عقدة (knot)', 1852 / 3600),
];

final pressureUnits = [
  Unit('باسكال (Pa)', 1),
  Unit('بار (bar)', 100000),
  Unit('PSI', 6894.757293168),
  Unit('ضغط جوي (atm)', 101325),
];

final energyUnits = [
  Unit('جول (J)', 1),
  Unit('كيلوواط ساعة (kWh)', 3.6e6),
  Unit('سعرة صغيرة (cal)', 4.184),
  Unit('سعرة غذائية (kcal)', 4184),
];

final dataUnits = [
  Unit('بت (bit)', 0.125),
  Unit('بايت (B)', 1),
  Unit('كيلوبايت (KB)', 1024),
  Unit('ميجابايت (MB)', 1024.0 * 1024),
  Unit('جيجابايت (GB)', 1024.0 * 1024 * 1024),
  Unit('تيرابايت (TB)', 1024.0 * 1024 * 1024 * 1024),
];

final timeUnits = [
  Unit('ثانية (s)', 1),
  Unit('دقيقة (min)', 60),
  Unit('ساعة (h)', 3600),
  Unit('يوم (d)', 86400),
  Unit('أسبوع (wk)', 604800),
];
