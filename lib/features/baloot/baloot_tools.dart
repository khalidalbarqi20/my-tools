import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'baloot_page.dart';

/// أداة مستقلة (بدون قسم): تظهر مع الأقسام في الرئيسية.
final List<Tool> balootTools = [
  Tool(
    id: 'baloot',
    nameAr: 'حاسبة البلوت',
    nameEn: 'Baloot Calculator',
    category: kStandalone,
    keywords: const [
      'بلوت', 'صن', 'حكم', 'مشاريع', 'سرا', 'صكة', 'ورق', 'لعبة', 'نقاط',
      'baloot', 'belote', 'cards', 'score'
    ],
    icon: Icons.style_outlined,
    builder: (_) => const BalootPage(),
  ),
];
