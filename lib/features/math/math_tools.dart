import 'package:flutter/material.dart';
import '../../core/tool.dart';
import '../text/text_tool_page.dart';
import 'cas.dart';
import 'cas_solve.dart';
import 'graph_page.dart';

Tool _mt(String id, String ar, String en, IconData icon, List<String> kw, String hint,
        String Function(String, Map<String, String>) run, {String? note}) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'math',
      keywords: kw,
      icon: icon,
      builder: (_) => TextToolPage(title: ar, hint: hint, run: run, note: note),
    );

final List<Tool> mathTools = [
  _mt(
    'math_solver',
    'حل المعادلات والمسائل (بالخطوات)',
    'Equation Solver',
    Icons.calculate_outlined,
    ['معادلة', 'معادلات', 'حل', 'مسألة', 'مجهول', 'س', 'نظام', 'متباينة', 'تربيعية', 'خطية', 'solve', 'equation', 'inequality', 'system', 'quadratic', 'algebra'],
    'اكتب المسألة، مثال:\n2x + 5 = 17\nx^2 - 5x + 6 = 0\n3x - 2 > 7\nلنظام معادلتين اكتب كل معادلة في سطر:\nx + y = 5\nx - y = 1',
    (s, o) => solveAny(s),
    note: 'محرك محلي بدون إنترنت. يدعم المعادلات الخطية والتربيعية وما فوقها (بالجذور النسبية)، والكسور والأسس، ونظام معادلتين، والمتباينات حتى الدرجة الثانية.',
  ),
  _mt(
    'math_simplify',
    'تبسيط التعبيرات الجبرية',
    'Simplify Expression',
    Icons.auto_fix_high,
    ['تبسيط', 'تعبير', 'جبر', 'فك الاقواس', 'اختصار', 'simplify', 'expand', 'algebra'],
    'مثال: 2x + 3x - 5\nأو (x+1)^2\nأو 3(x+2) - 2(x-1)',
    (s, o) => simplifyText(s),
  ),
  _mt(
    'math_factor',
    'التحليل إلى عوامل',
    'Factor Expression',
    Icons.account_tree_outlined,
    ['تحليل', 'عوامل', 'تحليل العوامل', 'factor', 'factorization', 'factorise'],
    'مثال: x^2 - 5x + 6\nأو 6x^2 + x - 1\nأو x^3 - 6x^2 + 11x - 6',
    (s, o) => factorText(s),
    note: 'يحلل كثيرات الحدود ذات المتغير الواحد بالجذور النسبية، ويُخرج العامل المشترك لعدة متغيرات.',
  ),
  Tool(
    id: 'math_graph',
    nameAr: 'الرسم البياني للدوال',
    nameEn: 'Function Grapher',
    category: 'math',
    keywords: ['رسم', 'رسم بياني', 'دالة', 'منحنى', 'جذور', 'تقاطع', 'graph', 'plot', 'function', 'curve', 'roots'],
    icon: Icons.show_chart,
    builder: (_) => const GraphPage(),
  ),
];
