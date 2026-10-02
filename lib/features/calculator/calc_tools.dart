import 'package:flutter/material.dart';
import '../../core/calc_page.dart';
import '../../core/fmt.dart';
import '../../core/tool.dart';
import 'calc_logic.dart';
import 'calculator_page.dart';
import 'discount_page.dart';
import 'finance_logic.dart';

Tool _calc({
  required String id,
  required String ar,
  required String en,
  required List<String> kw,
  required IconData icon,
  required List<CalcField> fields,
  required Rows? Function(List<String>) fn,
  String? note,
}) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'calc',
      keywords: kw,
      icon: icon,
      builder: (_) =>
          CalcPage(title: ar, fields: fields, compute: fn, note: note),
    );

final List<Tool> calcTools = [
  Tool(
    id: 'calculator',
    nameAr: 'حاسبة عادية',
    nameEn: 'Calculator',
    category: 'calc',
    keywords: ['آلة حاسبة', 'جمع', 'طرح', 'ضرب', 'قسمة', 'calculator', 'calc'],
    icon: Icons.calculate,
    builder: (_) => const CalculatorPage(),
  ),
  Tool(
    id: 'discount',
    nameAr: 'حاسبة الخصم',
    nameEn: 'Discount Calculator',
    category: 'calc',
    keywords: ['خصم', 'تخفيض', 'تنزيل', 'discount', 'sale'],
    icon: Icons.percent,
    builder: (_) => const DiscountPage(),
  ),
  _calc(
    id: 'percent', ar: 'النسبة المئوية', en: 'Percentage',
    kw: ['نسبة', 'مئوية', 'بالمئة', 'percent', 'percentage'],
    icon: Icons.donut_large, fn: percent,
    fields: [CalcField('الرقم الأول'), CalcField('الرقم الثاني')],
  ),
  _calc(
    id: 'tax', ar: 'حاسبة الضريبة', en: 'Tax Calculator',
    kw: ['ضريبة', 'قيمة مضافة', 'vat', 'tax'],
    icon: Icons.receipt_long, fn: tax,
    note: 'النسبة الافتراضية 15% وتقدر تغيّرها حسب الحاجة',
    fields: [CalcField('السعر'), CalcField('نسبة الضريبة %', initial: '15')],
  ),
  _calc(
    id: 'profit', ar: 'الربح والخسارة', en: 'Profit & Loss',
    kw: ['ربح', 'خسارة', 'هامش', 'تكلفة', 'profit', 'loss', 'margin'],
    icon: Icons.trending_up, fn: profit,
    fields: [CalcField('سعر التكلفة'), CalcField('سعر البيع')],
  ),
  _calc(
    id: 'tip', ar: 'حاسبة الإكرامية', en: 'Tip Calculator',
    kw: ['اكرامية', 'بقشيش', 'tip'],
    icon: Icons.room_service_outlined, fn: tip,
    fields: [CalcField('قيمة الفاتورة'), CalcField('نسبة الإكرامية %', initial: '10')],
  ),
  _calc(
    id: 'split', ar: 'تقسيم الفاتورة', en: 'Split Bill',
    kw: ['تقسيم', 'فاتورة', 'اشخاص', 'split', 'bill'],
    icon: Icons.call_split, fn: split,
    fields: [
      CalcField('قيمة الفاتورة'),
      CalcField('عدد الأشخاص', initial: '2'),
      CalcField('الإكرامية %', initial: '0'),
    ],
  ),
  _calc(
    id: 'bmi', ar: 'حاسبة BMI', en: 'BMI Calculator',
    kw: ['وزن', 'طول', 'كتلة الجسم', 'سمنة', 'bmi', 'weight'],
    icon: Icons.monitor_weight_outlined, fn: bmi,
    note: 'للمعلومات العامة وليست استشارة طبية',
    fields: [CalcField('الوزن (كجم)'), CalcField('الطول (سم)')],
  ),
  _calc(
    id: 'age', ar: 'حاسبة العمر', en: 'Age Calculator',
    kw: ['عمر', 'ميلاد', 'تاريخ', 'age', 'birthday'],
    icon: Icons.cake_outlined, fn: age,
    fields: [
      CalcField('سنة الميلاد (مثال 1995)'),
      CalcField('شهر الميلاد (1-12)'),
      CalcField('يوم الميلاد'),
    ],
  ),
  _calc(
    id: 'loan', ar: 'حاسبة القسط والقرض', en: 'Loan Calculator',
    kw: ['قسط', 'قرض', 'تمويل', 'loan', 'installment', 'mortgage'],
    icon: Icons.account_balance_outlined, fn: loan,
    note: 'تقدير تقريبي بطريقة القسط الثابت، وقد تختلف طريقة الحساب عند الجهة المقرضة',
    fields: [
      CalcField('مبلغ القرض'),
      CalcField('نسبة الفائدة السنوية %'),
      CalcField('عدد الأشهر'),
    ],
  ),
  _calc(
    id: 'savings', ar: 'حاسبة الادخار', en: 'Savings Calculator',
    kw: ['ادخار', 'توفير', 'استثمار', 'savings', 'invest'],
    icon: Icons.savings_outlined, fn: savings,
    note: 'تقدير نظري بعائد ثابت، والعائد الفعلي يختلف',
    fields: [
      CalcField('المبلغ الحالي', initial: '0'),
      CalcField('الإيداع الشهري'),
      CalcField('العائد السنوي المتوقع %', initial: '0'),
      CalcField('عدد السنوات'),
    ],
  ),
  _calc(
    id: 'interest', ar: 'حاسبة الفائدة', en: 'Interest Calculator',
    kw: ['فائدة', 'مركبة', 'بسيطة', 'interest', 'compound'],
    icon: Icons.show_chart, fn: interest,
    fields: [
      CalcField('المبلغ'),
      CalcField('النسبة السنوية %'),
      CalcField('عدد السنوات'),
    ],
  ),
  _calc(
    id: 'average', ar: 'حاسبة المتوسط', en: 'Average Calculator',
    kw: ['متوسط', 'معدل', 'وسيط', 'average', 'mean', 'median'],
    icon: Icons.functions, fn: average,
    fields: [CalcField('الأرقام (افصل بينها بمسافة أو سطر جديد)', text: true)],
  ),
];
