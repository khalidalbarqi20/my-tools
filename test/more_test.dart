import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/core/fmt.dart' show Rows;
import 'package:my_tools/features/more/more_logic.dart';
import 'package:my_tools/features/time/time_logic.dart' show weekdayAr;

String? val(Rows? r, String label) {
  if (r == null) return null;
  for (final e in r) {
    if (e.$1 == label) return e.$2;
  }
  return null;
}


void main() {
  group('الهندسة', () {
    test('مستطيل ومربع ودائرة', () {
      final r = geoRect(['3', '4']);
      expect(val(r, 'المساحة'), '12');
      expect(val(r, 'المحيط'), '14');
      expect(val(r, 'القطر'), '5');
      expect(geoRect(['3', '-4']), isNull);
      expect(geoRect(['3', '']), isNull);
      expect(geoRect(['x', '4']), isNull);
      expect(val(geoSquare(['2']), 'المساحة'), '4');
      final c = geoCircle(['1']);
      expect(val(c, 'القطر'), '2');
      expect(val(c, 'المحيط'), '6.283');
      expect(val(c, 'المساحة'), '3.142');
    });
    test('مثلث بالأضلاع', () {
      final r = geoTriangleSides(['5', '3', '4']);
      expect(val(r, 'المساحة'), '6');
      expect(val(r, 'المحيط'), '12');
      expect(val(r, 'النوع'), 'مختلف الأضلاع، قائم الزاوية');
      expect(val(geoTriangleSides(['2', '2', '2']), 'النوع'), 'متساوي الأضلاع');
      expect(val(geoTriangleSides(['2', '2', '2']), 'المساحة'), '1.732');
      expect(val(geoTriangleSides(['2', '2', '3']), 'النوع'), 'متساوي الساقين');
      expect(geoTriangleSides(['1', '2', '3']), isNull);
      expect(val(geoTriangleBH(['10', '4']), 'المساحة'), '20');
    });
    test('مجسمات', () {
      expect(val(geoCube(['2']), 'الحجم'), '8');
      expect(val(geoCube(['2']), 'المساحة السطحية'), '24');
      expect(val(geoCube(['2']), 'قطر المكعب'), '3.464');
      expect(val(geoCuboid(['2', '3', '4']), 'الحجم'), '24');
      expect(val(geoCuboid(['2', '3', '4']), 'المساحة السطحية'), '52');
      final cy = geoCylinder(['2', '5']);
      expect(val(cy, 'الحجم'), '62.832');
      expect(val(cy, 'المساحة الجانبية'), '62.832');
      expect(val(cy, 'المساحة الكلية'), '87.965');
      final co = geoCone(['3', '4']);
      expect(val(co, 'الحجم'), '37.699');
      expect(val(co, 'الارتفاع المائل'), '5');
      expect(val(co, 'المساحة الجانبية'), '47.124');
      expect(val(co, 'المساحة الكلية'), '75.398');
      expect(val(geoSphere(['1']), 'الحجم'), '4.189');
      expect(val(geoSphere(['1']), 'المساحة السطحية'), '12.566');
      expect(val(geoTrapezoid(['3', '5', '2']), 'المساحة'), '8');
      expect(val(geoParallelogram(['4', '3', '5']), 'المحيط'), '18');
    });
    test('فيثاغورس', () {
      expect(val(pythagoras(['3', '4', '']), 'الوتر (ج)'), '5');
      expect(val(pythagoras(['', '4', '5']), 'الضلع الأول (أ)'), '3');
      expect(val(pythagoras(['3', '', '5']), 'الضلع الثاني (ب)'), '4');
      expect(val(pythagoras(['3', '4', '5']), 'مثلث قائم؟'), 'نعم');
      expect(val(pythagoras(['3', '4', '6']), 'مثلث قائم؟'), 'لا');
      expect(pythagoras(['3', '', '']), isNull);
      expect(pythagoras(['5', '', '4']), isNull);
      expect(pythagoras(['0', '4', '']), isNull);
    });
    test('حل المثلث القائم', () {
      final r = rightTriangle(['3', '4', '', '']);
      expect(val(r, 'الوتر'), '5');
      expect(val(r, 'الزاوية (أ)'), '36.87°');
      expect(val(r, 'الزاوية الأخرى'), '53.13°');
      final r2 = rightTriangle(['', '', '10', '30']);
      expect(val(r2, 'الضلع المقابل'), '5');
      expect(val(r2, 'الضلع المجاور'), '8.66');
      expect(rightTriangle(['', '', '', '30']), isNull);
      expect(rightTriangle(['3', '4', '5', '']), isNull);
      expect(rightTriangle(['3', '', '', '90']), isNull);
      expect(rightTriangle(['5', '', '4', '']), isNull);
    });
  });

  group('العلوم', () {
    const sp = ['السرعة', 'المسافة', 'الزمن'];
    test('قوانين من ثلاثة متغيرات', () {
      expect(val(solveTriple(['', '100', '2'], mul: false, labels: sp), 'السرعة'), '50');
      expect(val(solveTriple(['60', '', '2'], mul: false, labels: sp), 'المسافة'), '120');
      expect(val(solveTriple(['60', '120', ''], mul: false, labels: sp), 'الزمن'), '2');
      expect(solveTriple(['', '10', '0'], mul: false, labels: sp), isNull);
      expect(solveTriple(['', '', '2'], mul: false, labels: sp), isNull);
      expect(solveTriple(['1', '2', '3'], mul: false, labels: sp), isNull);
      const f = ['القوة', 'الكتلة', 'التسارع'];
      expect(val(solveTriple(['', '10', '9.8'], mul: true, labels: f), 'القوة'), '98');
      expect(val(solveTriple(['98', '', '9.8'], mul: true, labels: f), 'الكتلة'), '10');
      expect(val(solveTriple(['98', '10', ''], mul: true, labels: f), 'التسارع'), '9.8');
      expect(solveTriple(['98', '0', ''], mul: true, labels: f), isNull);
    });
    test('الطاقة', () {
      expect(val(energyRows(['2', '3', '']), 'الطاقة الحركية (جول)'), '9');
      expect(val(energyRows(['2', '', '10']), 'طاقة الوضع (جول)'), '196.133');
      expect(val(energyRows(['2', '3', '10']), 'المجموع (جول)'), '205.133');
      expect(energyRows(['2', '', '']), isNull);
      expect(energyRows(['0', '3', '']), isNull);
    });
    test('الإحصاء', () {
      final t = statsText('2 4 4 4 5 5 7 9');
      expect(t, contains('العدد: 8'));
      expect(t, contains('المتوسط: 5'));
      expect(t, contains('الوسيط: 4.5'));
      expect(t, contains('المنوال: 4\n'));
      expect(t, contains('المدى: 7'));
      expect(t, contains('الانحراف المعياري (مجتمع): 2\n'));
      expect(t, contains('التباين (عينة): 4.571428571'));
      expect(statsText('1 2 3'), contains('المنوال: لا يوجد'));
      expect(statsText('\u0663، \u0664\n5'), contains('العدد: 3'));
      expect(statsText('7'), isNot(contains('عينة')));
      expect(() => statsText('a b'), throwsFormatException);
      expect(() => statsText('  '), throwsFormatException);
    });
    test('الاحتمال والتباديل', () {
      final p = probabilityRows(['1', '6']);
      expect(val(p, 'الاحتمال'), '0.1667');
      expect(val(p, 'كنسبة مئوية'), '16.67%');
      expect(probabilityRows(['7', '6']), isNull);
      expect(probabilityRows(['1', '0']), isNull);
      final c = combinatoricsRows(['5', '2']);
      expect(val(c, 'التباديل P(5,2)'), '20');
      expect(val(c, 'التوافيق C(5,2)'), '10');
      expect(val(c, '5!'), '120');
      expect(combinatoricsRows(['5', '6']), isNull);
      expect(combinatoricsRows(['3.5', '1']), isNull);
      expect(combinatoricsRows(['501', '1']), isNull);
      expect(val(combinatoricsRows(['30', '15']), 'التوافيق C(30,15)'), '155117520');
    });
  });

  group('المال', () {
    test('سعر الوحدة', () {
      final t = unitPriceText('12 18\n20 27');
      expect(t, contains('1) الخيار 1: 12 بسعر 18 ← 1.5 للوحدة\n'));
      expect(t, contains('2) الخيار 2: 20 بسعر 27 ← 1.35 للوحدة  ✓ الأرخص'));
      expect(t, contains('بنسبة 10%'));
      expect(unitPriceText('\u0661\u0662 \u0661\u0668'), contains('1.5 للوحدة'));
      expect(unitPriceText('12 قطعة = 18 ريال'), contains('قطعة ريال'));
      expect(unitPriceText('10 5\n5 2.5'), contains('كل الخيارات بنفس سعر الوحدة'));
      expect(() => unitPriceText('abc'), throwsFormatException);
      expect(() => unitPriceText('0 5'), throwsFormatException);
      expect(() => unitPriceText(''), throwsFormatException);
    });
    test('الخصم المتتابع والسعر النهائي', () {
      final r = successiveDiscount(['100', '20', '10', ''])!;
      expect(r[0], ('بعد الخصم 1 (20%)', '80'));
      expect(r[1], ('بعد الخصم 2 (10%)', '72'));
      expect(r[2], ('السعر النهائي', '72'));
      expect(r[3], ('إجمالي الخصم الفعلي', '28%'));
      expect(successiveDiscount(['100', '', '', '']), isNull);
      expect(successiveDiscount(['100', '120', '', '']), isNull);
      expect(successiveDiscount(['0', '10', '', '']), isNull);
      final f = finalPrice(['100', '10', '15']);
      expect(val(f, 'السعر بعد الخصم'), '90');
      expect(val(f, 'قيمة الضريبة'), '13.5');
      expect(val(f, 'السعر النهائي'), '103.5');
      expect(finalPrice(['100', '', '15']), isNull);
    });
    test('الراتب', () {
      final r = salaryRows(['5000', '1250', '500', '', '10', '100']);
      expect(val(r, 'إجمالي الراتب'), '6750');
      expect(val(r, 'إجمالي الاستقطاعات'), '725');
      expect(val(r, 'الصافي'), '6025');
      expect(val(r, 'الصافي لليوم (÷30)'), '200.83');
      expect(salaryRows(['', '1', '', '', '', '']), isNull);
      expect(salaryRows(['5000', '', '', '', '120', '']), isNull);
    });
  });

  group('السيارة', () {
    test('الاستهلاك والوحدات', () {
      final e = fuelEconomy(['500', '40']);
      expect(val(e, 'لتر لكل 100 كم'), '8');
      expect(val(e, 'كم لكل لتر'), '12.5');
      expect(fuelEconomy(['500', '0']), isNull);
      for (final (v, from) in [('8', 'l100'), ('12.5', 'kmpl')]) {
        final t = fuelUnitsText(v, from);
        expect(t, contains('لتر لكل 100 كم: 8\n'));
        expect(t, contains('كم لكل لتر: 12.5\n'));
        expect(t, contains('(أمريكي): 29.4\n'));
        expect(t, contains('(بريطاني): 35.31'));
      }
      expect(() => fuelUnitsText('0', 'l100'), throwsFormatException);
      expect(() => fuelUnitsText('x', 'l100'), throwsFormatException);
    });
    test('مدة الرحلة وتقسيم التكلفة', () {
      expect(val(tripDuration(['300', '100', '']), 'مدة الرحلة'), '3 ساعة');
      expect(val(tripDuration(['300', '100', '30']), 'مدة الرحلة'), '3 ساعة و30 دقيقة');
      expect(val(tripDuration(['150', '100', '15']), 'مدة الرحلة'), '1 ساعة و45 دقيقة');
      expect(tripDuration(['300', '0', '']), isNull);
      final s = tripSplit(['300', '8', '2.5', '20', '4']);
      expect(val(s, 'تكلفة الوقود'), '60');
      expect(val(s, 'إجمالي الرحلة'), '80');
      expect(val(s, 'نصيب كل شخص'), '20');
      expect(tripSplit(['300', '8', '2.5', '', '0']), isNull);
      expect(tripSplit(['300', '8', '2.5', '', '2.5']), isNull);
    });
  });

  group('المنزل', () {
    test('الغرفة والبلاط', () {
      final r = roomAreaRows(['4', '5', '']);
      expect(val(r, 'مساحة الأرضية'), '20 م²');
      expect(val(r, 'المحيط'), '18 م');
      expect(val(r, 'مساحة الجدران'), isNull);
      final r3 = roomAreaRows(['4', '5', '3']);
      expect(val(r3, 'مساحة الجدران'), '54 م²');
      expect(val(r3, 'حجم الغرفة'), '60 م³');
      final t = tilesRows(['4', '5', '60', '60', '10', '']);
      expect(val(t, 'عدد البلاط بدون هدر'), '56');
      expect(val(t, 'عدد البلاط مع الهدر (10%)'), '62');
      expect(val(t, 'عدد الكراتين'), isNull);
      expect(val(tilesRows(['4', '5', '60', '60', '10', '4']), 'عدد الكراتين'), '16');
      final exact = tilesRows(['4', '5', '50', '50', '0', '']);
      expect(val(exact, 'عدد البلاط بدون هدر'), '80');
      expect(val(exact, 'عدد البلاط مع الهدر (0%)'), '80');
      expect(tilesRows(['4', '5', '0', '60', '10', '']), isNull);
    });
    test('الدهان والخزانات', () {
      final p = paintRows(['4', '5', '3', '5', '2', '10']);
      expect(val(p, 'مساحة الجدران المطلوب دهانها'), '49 م²');
      expect(val(p, 'كمية الدهان'), '9.8 لتر');
      expect(val(p, 'مع احتياطي 10%'), '10.78 لتر');
      expect(paintRows(['1', '1', '1', '100', '2', '10']), isNull);
      expect(val(tankRect(['2', '1', '1']), 'السعة'), '2000 لتر');
      final c = tankCylinder(['1', '2']);
      expect(val(c, 'الحجم'), '1.571 م³');
      expect(val(c, 'السعة'), '1570.8 لتر');
    });
  });

  group('التاريخ والوقت', () {
    test('تحليل التاريخ', () {
      expect(fmtIsoDate(parseDate('2026-10-05')!), '2026-10-05');
      expect(fmtIsoDate(parseDate('5/10/2026')!), '2026-10-05');
      expect(fmtIsoDate(parseDate('\u0662\u0660\u0662\u0666-\u0661\u0660-\u0660\u0665')!), '2026-10-05');
      expect(parseDate('2026-02-30'), isNull);
      expect(parseDate('2026-13-01'), isNull);
      expect(parseDate('abc'), isNull);
      expect(parseDate(''), isNull);
    });
    test('إضافة مدة', () {
      expect(fmtIsoDate(addToDate(DateTime.utc(2026, 1, 31), months: 1)), '2026-02-28');
      expect(fmtIsoDate(addToDate(DateTime.utc(2024, 1, 31), months: 1)), '2024-02-29');
      final d = DateTime.utc(2026, 10, 5);
      expect(fmtIsoDate(addToDate(d, days: 30)), '2026-11-04');
      expect(fmtIsoDate(addToDate(d, days: -5)), '2026-09-30');
      expect(fmtIsoDate(addToDate(d, years: 1)), '2027-10-05');
      expect(fmtIsoDate(addToDate(d, months: -10)), '2025-12-05');
      final r = addDatesRows(['2026-10-05', '30', '', '']);
      expect(val(r, 'التاريخ الناتج'), '2026-11-04');
      expect(val(r, 'يوم الأسبوع'), weekdayAr(DateTime.utc(2026, 11, 4)));
      expect(addDatesRows(['bad', '1', '', '']), isNull);
      expect(addDatesRows(['2026-10-05', '1.5', '', '']), isNull);
    });
    test('يوم الأسبوع والأسبوع ISO', () {
      final r = weekdayRows(['2026-10-05']);
      expect(val(r, 'يوم الأسبوع'), 'الاثنين');
      expect(val(r, 'ترتيب اليوم في السنة'), '278');
      expect(val(r, 'رقم الأسبوع في السنة'), '41');
      expect(val(r, 'السنة'), 'عادية');
      expect(val(weekdayRows(['2024-02-29']), 'السنة'), 'كبيسة');
      expect(isoWeek(DateTime.utc(2021, 1, 3)), 53);
      expect(isoWeek(DateTime.utc(2024, 12, 30)), 1);
      expect(isoWeek(DateTime.utc(2026, 1, 1)), 1);
      expect(weekdayRows(['x']), isNull);
    });
    test('الأوقات وساعات العمل', () {
      expect(parseClock('9:30'), 34200);
      expect(parseClock('\u0660\u0669:\u0663\u0660'), 34200);
      expect(parseClock('30:15:10'), 108910);
      expect(parseClock('9:60'), isNull);
      expect(parseClock('x'), isNull);
      expect(parseClock('1000:00'), isNull);
      expect(fmtHms(3725), '01:02:05');
      final w = workHoursRows(['08:30', '17:00', '30', '', '1']);
      expect(val(w, 'ساعات العمل اليومية'), '8 ساعة');
      expect(val(w, 'بالساعات العشرية'), '8');
      final w2 = workHoursRows(['08:00', '16:00', '', '25', '5']);
      expect(val(w2, 'الأجر اليومي'), '200');
      expect(val(w2, 'إجمالي 5 يوم'), '40 ساعة');
      expect(val(w2, 'إجمالي الأجر'), '1000');
      expect(val(workHoursRows(['22:00', '06:00', '', '', '1']), 'ساعات العمل اليومية'), '8 ساعة');
      expect(workHoursRows(['08:00', '08:00', '', '', '1']), isNull);
      expect(workHoursRows(['08:00', '09:00', '90', '', '1']), isNull);
      final a = addTimeRows(['01:30', '00:45']);
      expect(val(a, 'المجموع'), '02:15:00');
      expect(val(a, 'الفرق'), '00:45:00');
      expect(val(addTimeRows(['00:45', '01:30']), 'الفرق'), '-00:45:00');
      expect(val(addTimeRows(['30:00', '05:00']), 'المجموع'), '35:00:00');
      expect(addTimeRows(['x', '1']), isNull);
    });
  });

  group('أدوات النصوص', () {
    test('JSON', () {
      const j = '{"a":1,"b":[1,2]}';
      expect(jsonTool(j, 'minify'), j);
      expect(jsonTool(' { "a" : 1 , "b" : [ 1 , 2 ] } ', 'minify'), j);
      expect(jsonTool(j, 'format'), '{\n  "a": 1,\n  "b": [\n    1,\n    2\n  ]\n}');
      expect(jsonTool(j, 'validate'),
          'JSON صالح ✓\nالنوع: كائن (Object)\nعدد العناصر في المستوى الأول: 2\nعمق التداخل: 2');
      expect(jsonTool('[1,2,3]', 'validate'), contains('مصفوفة (Array)'));
      expect(jsonTool('5', 'validate'), contains('قيمة مفردة'));
      expect(() => jsonTool('{"a":}', 'format'), throwsA(isA<FormatException>()));
      expect(() => jsonTool('{"a":1', 'format'), throwsA(isA<FormatException>()));
      expect(() => jsonTool('   ', 'format'), throwsFormatException);
    });
    test('Base64', () {
      expect(base64Tool('\u0645\u0631\u062D\u0628\u0627', decode: false), '2YXYsdit2KjYpw==');
      expect(base64Tool('2YXYsdit2KjYpw==', decode: true), '\u0645\u0631\u062D\u0628\u0627');
      expect(base64Tool('>>>???', decode: false), 'Pj4+Pz8/');
      expect(base64Tool('>>>???', decode: false, urlSafe: true), 'Pj4-Pz8_');
      expect(base64Tool('Pj4-Pz8_', decode: true), '>>>???');
      expect(base64Tool('YQ', decode: true), 'a');
      expect(base64Tool('Y Q = =', decode: true), 'a');
      expect(() => base64Tool('***', decode: true), throwsFormatException);
      expect(() => base64Tool('/w==', decode: true), throwsFormatException); // بايت غير UTF-8
    });
    test('URL', () {
      expect(urlTool('a b&c=d/\u00E9', decode: false), 'a%20b%26c%3Dd%2F%C3%A9');
      expect(urlTool('https://x.com/a b?q=\u00E9', decode: false, full: true), 'https://x.com/a%20b?q=%C3%A9');
      expect(urlTool('a%20b', decode: true), 'a b');
      expect(urlTool('%C3%A9', decode: true), '\u00E9');
      expect(() => urlTool('%E0%A4%A', decode: true), throwsFormatException);
    });
  });
}
