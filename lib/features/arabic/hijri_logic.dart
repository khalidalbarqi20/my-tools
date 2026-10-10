import 'package:hijri_core/hijri_core.dart';
import '../extras/extras_logic.dart' show toWesternDigits;
import '../more/more_logic.dart' show fmtIsoDate, parseDate;
import '../time/time_logic.dart' show weekdayAr;

const hijriMonths = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
  'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];

const _range = 'التاريخ خارج النطاق المدعوم (من 1900م إلى 2076م، أي 1318هـ إلى 1500هـ)';

(int, int, int)? _ymd(String s) {
  final t = toWesternDigits(s).trim();
  var m = RegExp(r'^(\d{3,4})\D+(\d{1,2})\D+(\d{1,2})$').firstMatch(t);
  if (m != null) return (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  m = RegExp(r'^(\d{1,2})\D+(\d{1,2})\D+(\d{3,4})$').firstMatch(t);
  if (m != null) return (int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
  return null;
}

String _p2(int v) => v.toString().padLeft(2, '0');

/// تحويل بين الميلادي والهجري (تقويم أم القرى). اكتب «اليوم» لتاريخ اليوم عند التحويل للهجري.
String hijriConvert(String input, {required bool toHijriDir, DateTime? now}) {
  final raw = input.trim();
  if (toHijriDir) {
    DateTime? d;
    if (raw == 'اليوم' || raw.toLowerCase() == 'today') {
      final n = now ?? DateTime.now();
      d = DateTime.utc(n.year, n.month, n.day);
    } else {
      d = parseDate(raw);
    }
    if (d == null) {
      throw const FormatException('اكتب التاريخ الميلادي هكذا: 2026-10-05 (سنة-شهر-يوم) أو كلمة «اليوم»');
    }
    final h = toHijri(d);
    if (h == null) throw const FormatException(_range);
    return 'الميلادي: ${fmtIsoDate(d)} (${weekdayAr(d)})\n'
        'الهجري: ${h.hd} ${hijriMonths[h.hm - 1]} ${h.hy} هـ\n'
        'بالأرقام: ${h.hy}/${_p2(h.hm)}/${_p2(h.hd)}';
  }
  final p = _ymd(raw);
  if (p == null) {
    throw const FormatException('اكتب التاريخ الهجري هكذا: 1448-04-23 (سنة-شهر-يوم)');
  }
  final (y, m, d) = p;
  if (m < 1 || m > 12 || d < 1 || d > 30) {
    throw const FormatException('الشهر من 1 إلى 12 والأيام من 1 إلى 30');
  }
  if (!isValidHijriDate(y, m, d)) {
    throw const FormatException('هذا التاريخ غير موجود في التقويم الهجري، أو خارج النطاق المدعوم (1318 إلى 1500هـ)');
  }
  final g = toGregorian(y, m, d);
  if (g == null) throw const FormatException(_range);
  return 'الهجري: $d ${hijriMonths[m - 1]} $y هـ\n'
      'الميلادي: ${fmtIsoDate(g)} (${weekdayAr(g)})';
}
