/// منطق أدوات الشبكة (دوال نقية قابلة للاختبار).
library;

class PingStats {
  final int sent, lost;
  final double min, avg, max, jitter;
  const PingStats(this.sent, this.lost, this.min, this.avg, this.max, this.jitter);
  double get lossPct => sent == 0 ? 0 : lost * 100 / sent;
}

/// [ms] أزمنة الاستجابة الناجحة بالملي ثانية، و[sent] عدد المحاولات الكلي.
/// التذبذب = متوسط الفرق المطلق بين قياسين متتاليين.
PingStats pingStats(List<double> ms, int sent) {
  if (ms.isEmpty) return PingStats(sent, sent, 0, 0, 0, 0);
  var mn = ms.first, mx = ms.first, sum = 0.0;
  for (final v in ms) {
    if (v < mn) mn = v;
    if (v > mx) mx = v;
    sum += v;
  }
  var j = 0.0;
  for (var i = 1; i < ms.length; i++) {
    j += (ms[i] - ms[i - 1]).abs();
  }
  final jitter = ms.length > 1 ? j / (ms.length - 1) : 0.0;
  return PingStats(sent, sent - ms.length, mn, sum / ms.length, mx, jitter);
}

/// السرعة بالميجابت/ثانية من عدد البايتات والمدة.
double mbps(int bytes, Duration d) {
  final s = d.inMicroseconds / 1e6;
  if (s <= 0) return 0;
  return bytes * 8 / s / 1e6;
}

/// يضيف https:// إن لم يكتب المستخدم بروتوكولًا، ويرجع null إذا كان العنوان غير صالح.
Uri? normalizeUrl(String s) {
  var t = s.trim();
  if (t.isEmpty || t.contains(' ')) return null;
  if (!RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(t)) {
    t = 'https://$t';
  }
  final u = Uri.tryParse(t);
  if (u == null || u.host.isEmpty || !u.host.contains('.')) return null;
  if (u.scheme != 'http' && u.scheme != 'https') return null;
  return u;
}

const dnsTypes = {'A': 1, 'AAAA': 28, 'CNAME': 5, 'MX': 15, 'NS': 2, 'TXT': 16};

String dnsTypeName(int code) {
  for (final e in dnsTypes.entries) {
    if (e.value == code) return e.key;
  }
  return '$code';
}

String dnsStatusAr(int s) {
  switch (s) {
    case 0:
      return 'تمّ بنجاح';
    case 2:
      return 'فشل الخادم';
    case 3:
      return 'الاسم غير موجود';
    case 5:
      return 'مرفوض';
    default:
      return 'رمز $s';
  }
}
