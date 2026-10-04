import 'dart:convert';

class CurrencyInfo {
  final String code, nameAr;
  const CurrencyInfo(this.code, this.nameAr);
}

/// عملات مختارة ومعروفة فقط (بدون عملات رقمية أو عملات منتهية).
const currencyList = <CurrencyInfo>[
  CurrencyInfo('sar', 'ريال سعودي'),
  CurrencyInfo('usd', 'دولار أمريكي'),
  CurrencyInfo('eur', 'يورو'),
  CurrencyInfo('gbp', 'جنيه إسترليني'),
  CurrencyInfo('aed', 'درهم إماراتي'),
  CurrencyInfo('kwd', 'دينار كويتي'),
  CurrencyInfo('qar', 'ريال قطري'),
  CurrencyInfo('bhd', 'دينار بحريني'),
  CurrencyInfo('omr', 'ريال عماني'),
  CurrencyInfo('jod', 'دينار أردني'),
  CurrencyInfo('egp', 'جنيه مصري'),
  CurrencyInfo('iqd', 'دينار عراقي'),
  CurrencyInfo('lbp', 'ليرة لبنانية'),
  CurrencyInfo('syp', 'ليرة سورية'),
  CurrencyInfo('yer', 'ريال يمني'),
  CurrencyInfo('mad', 'درهم مغربي'),
  CurrencyInfo('dzd', 'دينار جزائري'),
  CurrencyInfo('tnd', 'دينار تونسي'),
  CurrencyInfo('lyd', 'دينار ليبي'),
  CurrencyInfo('sdg', 'جنيه سوداني'),
  CurrencyInfo('try', 'ليرة تركية'),
  CurrencyInfo('irr', 'ريال إيراني'),
  CurrencyInfo('ils', 'شيكل إسرائيلي'),
  CurrencyInfo('inr', 'روبية هندية'),
  CurrencyInfo('pkr', 'روبية باكستانية'),
  CurrencyInfo('bdt', 'تاكا بنغلاديشية'),
  CurrencyInfo('lkr', 'روبية سريلانكية'),
  CurrencyInfo('npr', 'روبية نيبالية'),
  CurrencyInfo('php', 'بيزو فلبيني'),
  CurrencyInfo('idr', 'روبية إندونيسية'),
  CurrencyInfo('myr', 'رينغيت ماليزي'),
  CurrencyInfo('sgd', 'دولار سنغافوري'),
  CurrencyInfo('thb', 'بات تايلندي'),
  CurrencyInfo('cny', 'يوان صيني'),
  CurrencyInfo('jpy', 'ين ياباني'),
  CurrencyInfo('krw', 'وون كوري'),
  CurrencyInfo('hkd', 'دولار هونغ كونغ'),
  CurrencyInfo('aud', 'دولار أسترالي'),
  CurrencyInfo('nzd', 'دولار نيوزيلندي'),
  CurrencyInfo('cad', 'دولار كندي'),
  CurrencyInfo('chf', 'فرنك سويسري'),
  CurrencyInfo('sek', 'كرونة سويدية'),
  CurrencyInfo('nok', 'كرونة نرويجية'),
  CurrencyInfo('dkk', 'كرونة دنماركية'),
  CurrencyInfo('rub', 'روبل روسي'),
  CurrencyInfo('uah', 'هريفنيا أوكرانية'),
  CurrencyInfo('pln', 'زلوتي بولندي'),
  CurrencyInfo('czk', 'كرونة تشيكية'),
  CurrencyInfo('huf', 'فورنت مجري'),
  CurrencyInfo('brl', 'ريال برازيلي'),
  CurrencyInfo('mxn', 'بيزو مكسيكي'),
  CurrencyInfo('ars', 'بيزو أرجنتيني'),
  CurrencyInfo('zar', 'راند جنوب أفريقي'),
  CurrencyInfo('ngn', 'نايرا نيجيرية'),
  CurrencyInfo('kes', 'شلن كيني'),
];

String currencyName(String code) {
  for (final c in currencyList) {
    if (c.code == code) return '${c.nameAr} (${code.toUpperCase()})';
  }
  return code.toUpperCase();
}

/// لقطة أسعار: كم وحدة من كل عملة تساوي 1 دولار.
class RatesSnapshot {
  final Map<String, double> perUsd;
  final String apiDate; // تاريخ الأسعار حسب المصدر (yyyy-mm-dd)
  final DateTime fetchedAt; // وقت تحميلها على الجهاز
  const RatesSnapshot(this.perUsd, this.apiDate, this.fetchedAt);

  Map<String, dynamic> toJson() => {
        'perUsd': perUsd,
        'apiDate': apiDate,
        'fetchedAt': fetchedAt.millisecondsSinceEpoch,
      };

  static RatesSnapshot? fromJson(Object? j) {
    try {
      if (j is! Map) return null;
      final raw = j['perUsd'];
      final at = j['fetchedAt'];
      if (raw is! Map || at is! int) return null;
      final m = _cleanRates(raw);
      if (m == null) return null;
      return RatesSnapshot(
          m, (j['apiDate'] ?? '').toString(), DateTime.fromMillisecondsSinceEpoch(at));
    } catch (_) {
      return null;
    }
  }

  List<CurrencyInfo> get available =>
      currencyList.where((c) => perUsd.containsKey(c.code)).toList();
}

Map<String, double>? _cleanRates(Map raw) {
  final out = <String, double>{};
  raw.forEach((k, v) {
    if (k is String && v is num) {
      final d = v.toDouble();
      if (d.isFinite && d > 0) out[k.toLowerCase()] = d;
    }
  });
  out['usd'] = 1;
  // بيانات ناقصة: نرفضها بدل عرض نتائج مضللة.
  return out.length >= 20 ? out : null;
}

/// يحلل رد المصدر (قاعدة usd). يرجع null عند أي بيانات ناقصة أو غير صالحة.
RatesSnapshot? parseRates(String body, DateTime now) {
  try {
    final j = jsonDecode(body);
    if (j is! Map) return null;
    final usd = j['usd'];
    if (usd is! Map) return null;
    final m = _cleanRates(usd);
    if (m == null) return null;
    return RatesSnapshot(m, (j['date'] ?? '').toString(), now);
  } catch (_) {
    return null;
  }
}

double? convertCurrency(double amount, String from, String to, RatesSnapshot s) {
  final a = s.perUsd[from], b = s.perUsd[to];
  if (a == null || b == null || !amount.isFinite) return null;
  final r = amount / a * b;
  return r.isFinite ? r : null;
}

String _unit(int n, String one, String two, String few, String many) {
  if (n == 1) return 'منذ $one';
  if (n == 2) return 'منذ $two';
  return 'منذ $n ${n <= 10 ? few : many}';
}

/// عمر آخر تحديث على الجهاز بالعربية.
String ageLabel(DateTime fetched, DateTime now) {
  final d = now.difference(fetched);
  if (d.inMinutes < 1) return 'قبل لحظات';
  if (d.inHours < 1) {
    return _unit(d.inMinutes, 'دقيقة', 'دقيقتين', 'دقائق', 'دقيقة');
  }
  if (d.inDays < 1) return _unit(d.inHours, 'ساعة', 'ساعتين', 'ساعات', 'ساعة');
  return _unit(d.inDays, 'يوم', 'يومين', 'أيام', 'يومًا');
}

/// هل الأسعار قديمة؟ (أكثر من 3 أيام من تاريخ المصدر أو من التحميل)
bool isStale(RatesSnapshot s, DateTime now) {
  final d = DateTime.tryParse(s.apiDate) ?? s.fetchedAt;
  return now.difference(d).inDays >= 3;
}
