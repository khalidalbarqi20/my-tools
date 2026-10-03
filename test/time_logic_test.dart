import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/time/time_logic.dart';

void main() {
  test('fmtClock', () {
    expect(fmtClock(const Duration(seconds: 3725)), '01:02:05');
    expect(fmtClock(const Duration(milliseconds: 400)), '00:00:01');
    expect(fmtClock(Duration.zero), '00:00:00');
    expect(fmtClock(const Duration(seconds: -5)), '00:00:00');
  });
  test('fmtStopwatch', () {
    expect(fmtStopwatch(const Duration(minutes: 1, seconds: 5, milliseconds: 230)), '01:05.23');
    expect(fmtStopwatch(const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 450)), '1:02:03.45');
    expect(fmtStopwatch(Duration.zero), '00:00.00');
  });
  test('breakdown', () {
    final b = breakdown(const Duration(days: 2, hours: 3, minutes: 4, seconds: 5));
    expect([b.days, b.hours, b.minutes, b.seconds], [2, 3, 4, 5]);
    expect(breakdown(const Duration(milliseconds: 1500)).seconds, 2);
    expect(breakdown(const Duration(hours: -1)).hours, 1);
  });
  test('التواريخ', () {
    expect(fmtDate(DateTime(2026, 3, 5)), '2026/03/05');
    expect(fmtTime(DateTime(2026, 3, 5, 7, 9)), '07:09');
    expect(weekdayAr(DateTime(2026, 10, 4)), 'الأحد');
    expect(addDays(DateTime(2026, 10, 4), 30), DateTime(2026, 11, 3));
    expect(addDays(DateTime(2026, 10, 4), -4), DateTime(2026, 9, 30));
    expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
  });
  test('dateDiff', () {
    var r = dateDiff(DateTime(2020, 1, 15), DateTime(2021, 3, 20));
    expect([r.years, r.months, r.days, r.total], [1, 2, 5, 430]);
    r = dateDiff(DateTime(2021, 3, 20), DateTime(2020, 1, 15));
    expect([r.years, r.months, r.days, r.total], [1, 2, 5, 430]);
    r = dateDiff(DateTime(2020, 1, 31), DateTime(2020, 3, 1));
    expect([r.years, r.months, r.days, r.total], [0, 1, 1, 30]);
    r = dateDiff(DateTime(2021, 1, 31), DateTime(2021, 2, 28));
    expect([r.years, r.months, r.days, r.total], [0, 0, 28, 28]);
    r = dateDiff(DateTime(2020, 2, 29), DateTime(2021, 3, 1));
    expect([r.years, r.months, r.days], [1, 0, 1]);
    r = dateDiff(DateTime(2026, 5, 5), DateTime(2026, 5, 5));
    expect([r.years, r.months, r.days, r.total], [0, 0, 0, 0]);
  });
  test('فرق التوقيت', () {
    expect(offsetLabel(const Duration(hours: 3)), 'يسبق جهازك بـ 3 ساعات');
    expect(offsetLabel(const Duration(hours: -5, minutes: -30)),
        'يتأخر عن جهازك بـ 5 ساعات و30 دقيقة');
    expect(offsetLabel(Duration.zero), 'نفس توقيت جهازك');
    expect(hoursPhrase(const Duration(hours: 1)), 'ساعة');
    expect(hoursPhrase(const Duration(hours: 2)), 'ساعتان');
    expect(hoursPhrase(const Duration(hours: 11)), '11 ساعة');
    expect(hoursPhrase(const Duration(minutes: 45)), '45 دقيقة');
  });
  test('بومودورو', () {
    expect(pomoNext(PomoPhase.work, 1), PomoPhase.shortBreak);
    expect(pomoNext(PomoPhase.work, 4), PomoPhase.longBreak);
    expect(pomoNext(PomoPhase.work, 8), PomoPhase.longBreak);
    expect(pomoNext(PomoPhase.shortBreak, 1), PomoPhase.work);
    expect(pomoNext(PomoPhase.longBreak, 4), PomoPhase.work);
    expect(pomoMinutes('25', PomoPhase.work), 25);
    expect(pomoMinutes('25', PomoPhase.shortBreak), 5);
    expect(pomoMinutes('50', PomoPhase.longBreak), 30);
    expect(pomoMinutes('x', PomoPhase.work), 25);
  });
}
