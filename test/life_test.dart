import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/life/life_logic.dart';
import 'package:my_tools/features/life/prayer_logic.dart';

void main() {
  test('مواقيت الرياض ٢٧ أكتوبر ٢٠٢٦ (أم القرى)', () {
    final p = calcPrayer(DateTime(2026, 10, 27), 24.7136, 46.6753, 3);
    expect(p.fajr, closeTo(4.6386, 0.02));
    expect(p.sunrise, closeTo(5.9554, 0.02));
    expect(p.dhuhr, closeTo(11.6362, 0.02));
    expect(p.asr, closeTo(14.8632, 0.02));
    expect(p.maghrib, closeTo(17.2783, 0.02));
    expect(p.isha, closeTo(18.7783, 0.02));
    expect(p.fajr < p.sunrise && p.sunrise < p.dhuhr && p.dhuhr < p.asr, true);
    expect(p.asr < p.maghrib && p.maghrib < p.isha, true);
  });

  test('مكة صيفًا والعصر الحنفي', () {
    final p = calcPrayer(DateTime(2026, 6, 21), 21.4225, 39.8262, 3, hanafi: true);
    expect(p.fajr, closeTo(4.1879, 0.02));
    expect(p.asr, closeTo(17.0246, 0.02));
    expect(p.isha, closeTo(20.5947, 0.02));
    final s = calcPrayer(DateTime(2026, 6, 21), 21.4225, 39.8262, 3);
    expect(s.asr < p.asr, true);
  });

  test('القبلة', () {
    expect(qiblaBearing(24.7136, 46.6753), closeTo(243.8, 0.2));
    expect(qiblaBearing(40.7128, -74.006), closeTo(58.5, 0.2));
  });

  test('تنسيق الوقت والصلاة القادمة', () {
    expect(fmtHm(4.6386), '4:38 ص');
    expect(fmtHm(12.0), '12:00 م');
    expect(fmtHm(0.5), '12:30 ص');
    expect(fmtHm(17.2783, h12: false), '17:17');
    final n = nextPrayer(DateTime(2026, 10, 27, 12, 0), 24.7136, 46.6753, 3);
    expect(n.name, 'العصر');
    final late = nextPrayer(DateTime(2026, 10, 27, 23, 0), 24.7136, 46.6753, 3);
    expect(late.name, 'الفجر');
    expect(late.left.inHours, inInclusiveRange(5, 6));
  });

  test('سلسلة العادات', () {
    final today = DateTime(2026, 10, 27);
    expect(habitStreak({}, today), 0);
    expect(habitStreak({'2026-10-27', '2026-10-26', '2026-10-25'}, today), 3);
    expect(habitStreak({'2026-10-26', '2026-10-25'}, today), 2); // لم يُنجز اليوم بعد
    expect(habitStreak({'2026-10-27', '2026-10-25'}, today), 1);
    expect(habitStreak({'2026-10-30'}, today), 0);
    expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
  });

  test('تصفية المهام والبحث', () {
    final ts = [Task('1', 'أ', false), Task('2', 'ب', true)];
    expect(filterTasks(ts, 0).length, 2);
    expect(filterTasks(ts, 1).single.id, '1');
    expect(filterTasks(ts, 2).single.id, '2');
    final ns = [Note('1', 'قائمة التسوق', 'حليب', 0), Note('2', 'فكرة', 'تطبيق جديد', 0)];
    expect(searchNotes(ns, 'حليب').single.id, '1');
    expect(searchNotes(ns, '').length, 2);
    expect(searchNotes(ns, 'zzz'), isEmpty);
  });
}
