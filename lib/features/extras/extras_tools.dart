import 'package:flutter/material.dart';
import '../../core/calc_page.dart';
import '../../core/tool.dart';
import '../pdf/single_pdf_tool.dart' show Opt;
import '../text/text_tool_page.dart';
import 'extras_logic.dart';

final List<Tool> extrasTools = [
  Tool(
    id: 'calc_fuel',
    nameAr: 'تكلفة الوقود للرحلة',
    nameEn: 'Fuel Cost',
    category: 'car',
    keywords: ['بنزين', 'وقود', 'رحلة', 'سفر', 'سيارة', 'استهلاك', 'fuel', 'gas', 'trip', 'petrol'],
    icon: Icons.local_gas_station_outlined,
    builder: (_) => CalcPage(
      title: 'تكلفة الوقود للرحلة',
      fields: const [
        CalcField('المسافة (كم)'),
        CalcField('استهلاك السيارة (لتر لكل 100 كم)'),
        CalcField('سعر اللتر'),
      ],
      compute: fuelRows,
      note: 'للذهاب والعودة ضاعف المسافة. اكتب سعر اللتر الحالي في محطتك.',
    ),
  ),
  Tool(
    id: 'calc_zakat',
    nameAr: 'حاسبة الزكاة',
    nameEn: 'Zakat Calculator',
    category: 'calc',
    keywords: ['زكاة', 'نصاب', 'ذهب', 'مال', 'حول', 'zakat', 'nisab', 'gold'],
    icon: Icons.volunteer_activism_outlined,
    builder: (_) => CalcPage(
      title: 'حاسبة الزكاة',
      fields: const [
        CalcField('إجمالي المال الذي مرّ عليه حول كامل'),
        CalcField('سعر جرام الذهب عيار 24 اليوم'),
      ],
      compute: zakatRows,
      note: 'الزكاة 2.5% إذا بلغ المال نصاب 85 جرام ذهب ومرّ عليه سنة هجرية. '
          'الحساب تقريبي وليس فتوى، وللحالات الخاصة راجع جهة مختصة.',
    ),
  ),
  Tool(
    id: 'conv_base',
    nameAr: 'تحويل الأنظمة العددية',
    nameEn: 'Number Base Converter',
    category: 'convert',
    keywords: ['ثنائي', 'سداسي عشر', 'عشري', 'ثماني', 'binary', 'hex', 'decimal', 'octal', 'base'],
    icon: Icons.tag,
    builder: (_) => TextToolPage(
      title: 'تحويل الأنظمة العددية',
      hint: 'اكتب الرقم هنا...',
      options: const [
        Opt.choice(
            'from',
            'نظام الرقم المُدخل',
            [('2', 'ثنائي'), ('8', 'ثماني'), ('10', 'عشري'), ('16', 'سداسي عشر')],
            initial: '10'),
      ],
      run: (s, o) {
        final from = int.parse(o['from'] ?? '10');
        final m = convertBase(s, from);
        if (m == null) throw const FormatException('الرقم غير صالح للنظام المختار');
        return 'ثنائي (2): ${m[2]}\nثماني (8): ${m[8]}\nعشري (10): ${m[10]}\nسداسي عشر (16): ${m[16]}';
      },
    ),
  ),
  Tool(
    id: 'conv_roman',
    nameAr: 'الأرقام الرومانية',
    nameEn: 'Roman Numerals',
    category: 'convert',
    keywords: ['رومانية', 'رومان', 'roman', 'numerals', 'XIV'],
    icon: Icons.account_balance_outlined,
    builder: (_) => TextToolPage(
      title: 'الأرقام الرومانية',
      hint: 'اكتب رقمًا (مثل 2026) أو رقمًا رومانيًا (مثل XIV)',
      run: (s, o) => romanConvert(s),
    ),
  ),
  Tool(
    id: 'text_diacritics',
    nameAr: 'إزالة التشكيل',
    nameEn: 'Remove Diacritics',
    category: 'text',
    keywords: ['تشكيل', 'حركات', 'تطويل', 'كشيدة', 'عربي', 'diacritics', 'tashkeel', 'arabic', 'tatweel'],
    icon: Icons.format_clear,
    builder: (_) => TextToolPage(
      title: 'إزالة التشكيل',
      hint: 'الصق النص العربي المشكّل هنا...',
      options: const [
        Opt.toggle('tatweel', 'حذف التطويل (ـــ) أيضًا', on: true),
      ],
      run: (s, o) => stripArabicMarks(s, tatweel: o['tatweel'] == 'true'),
    ),
  ),
  Tool(
    id: 'text_digits',
    nameAr: 'تحويل الأرقام (عربية/إنجليزية)',
    nameEn: 'Arabic-Indic Digits',
    category: 'text',
    keywords: ['ارقام', 'أرقام', 'هندية', 'عربية', 'غربية', 'digits', 'numerals', 'arabic', 'persian'],
    icon: Icons.pin_outlined,
    builder: (_) => TextToolPage(
      title: 'تحويل الأرقام',
      hint: 'اكتب أو الصق نصًا فيه أرقام...',
      options: const [
        Opt.choice('mode', 'التحويل إلى',
            [('west', 'أرقام 123'), ('arabic', 'أرقام ١٢٣')],
            initial: 'west'),
      ],
      run: (s, o) => o['mode'] == 'arabic' ? toArabicIndicDigits(s) : toWesternDigits(s),
    ),
  ),
];
