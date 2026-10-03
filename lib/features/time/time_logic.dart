String p2(int n) => n.toString().padLeft(2, '0');

/// HH:MM:SS مع التقريب للأعلى (المتبقي 0.4 ثانية يظهر ثانية واحدة).
String fmtClock(Duration d) {
  final secs = d.isNegative ? 0 : (d.inMilliseconds / 1000).ceil();
  return '${p2(secs ~/ 3600)}:${p2((secs % 3600) ~/ 60)}:${p2(secs % 60)}';
}

String fmtStopwatch(Duration d) {
  final ms = d.inMilliseconds < 0 ? 0 : d.inMilliseconds;
  final cs = (ms % 1000) ~/ 10;
  final total = ms ~/ 1000;
  final base = '${p2((total ~/ 60) % 60)}:${p2(total % 60)}.${p2(cs)}';
  final h = total ~/ 3600;
  return h > 0 ? '$h:$base' : base;
}

({int days, int hours, int minutes, int seconds}) breakdown(Duration d) {
  final t = d.isNegative ? -d : d;
  final total = (t.inMilliseconds / 1000).ceil();
  return (
    days: total ~/ 86400,
    hours: (total % 86400) ~/ 3600,
    minutes: (total % 3600) ~/ 60,
    seconds: total % 60,
  );
}

String fmtDate(DateTime d) => '${d.year}/${p2(d.month)}/${p2(d.day)}';
String fmtTime(DateTime d) => '${p2(d.hour)}:${p2(d.minute)}';

const _wd = [
  'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
];
String weekdayAr(DateTime d) => _wd[d.weekday - 1];

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

DateTime _addMonths(DateTime d, int n) {
  final t = d.year * 12 + (d.month - 1) + n;
  final y = t ~/ 12, m = t % 12 + 1;
  final last = DateTime.utc(y, m + 1, 0).day;
  return DateTime.utc(y, m, d.day > last ? last : d.day);
}

/// الفرق بين تاريخين بالسنوات والأشهر والأيام (يتجاهل الوقت ويقبل أي ترتيب).
({int years, int months, int days, int total}) dateDiff(DateTime a, DateTime b) {
  var s = DateTime.utc(a.year, a.month, a.day);
  var e = DateTime.utc(b.year, b.month, b.day);
  if (e.isBefore(s)) {
    final t = s;
    s = e;
    e = t;
  }
  var months = (e.year - s.year) * 12 + e.month - s.month;
  if (e.day < s.day) months--;
  var cand = _addMonths(s, months);
  if (cand.isAfter(e)) {
    months--;
    cand = _addMonths(s, months);
  }
  return (
    years: months ~/ 12,
    months: months % 12,
    days: e.difference(cand).inDays,
    total: e.difference(s).inDays,
  );
}

String hoursPhrase(Duration d) {
  final m = d.inMinutes.abs();
  final h = m ~/ 60, mm = m % 60;
  final hs = h == 0
      ? ''
      : h == 1
          ? 'ساعة'
          : h == 2
              ? 'ساعتان'
              : h <= 10
                  ? '$h ساعات'
                  : '$h ساعة';
  final ms = mm == 0 ? '' : '$mm دقيقة';
  return [hs, ms].where((e) => e.isNotEmpty).join(' و');
}

String offsetLabel(Duration d) {
  if (d.inMinutes == 0) return 'نفس توقيت جهازك';
  return '${d.isNegative ? 'يتأخر عن' : 'يسبق'} جهازك بـ ${hoursPhrase(d)}';
}

enum PomoPhase { work, shortBreak, longBreak }

PomoPhase pomoNext(PomoPhase p, int completedWork) {
  if (p != PomoPhase.work) return PomoPhase.work;
  return completedWork % 4 == 0 ? PomoPhase.longBreak : PomoPhase.shortBreak;
}

int pomoMinutes(String preset, PomoPhase p) {
  final t = switch (preset) {
    '50' => (50, 10, 30),
    '15' => (15, 3, 10),
    _ => (25, 5, 15),
  };
  return switch (p) {
    PomoPhase.work => t.$1,
    PomoPhase.shortBreak => t.$2,
    PomoPhase.longBreak => t.$3,
  };
}
