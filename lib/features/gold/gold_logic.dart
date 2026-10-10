import '../currency/currency_logic.dart';

const troyOunceGrams = 31.1034768;
const goldKarats = [24, 22, 21, 18];

/// سعر أونصة الذهب بالدولار من لقطة الأسعار (المصدر يعطي الأونصات لكل دولار).
/// يرجع null إذا غابت البيانات أو بدت غير منطقية (حماية من عرض رقم خاطئ).
double? goldOunceUsd(RatesSnapshot s) {
  final x = s.perUsd['xau'];
  if (x == null || !(x > 0)) return null;
  final v = 1 / x;
  return v.isFinite && v >= 50 && v <= 500000 ? v : null;
}

double? goldOuncePrice(RatesSnapshot s, String cur) {
  final oz = goldOunceUsd(s), rate = s.perUsd[cur];
  if (oz == null || rate == null || !(rate > 0)) return null;
  return oz * rate;
}

/// سعر الجرام لعيار معيّن (الذهب الخام، بدون مصنعية).
double? goldGramPrice(RatesSnapshot s, String cur, int karat) {
  final oz = goldOuncePrice(s, cur);
  if (oz == null || karat < 1 || karat > 24) return null;
  return oz / troyOunceGrams * karat / 24;
}
