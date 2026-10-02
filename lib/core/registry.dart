import 'package:flutter/material.dart';
import 'tool.dart';
import '../features/calculator/discount_page.dart';

/// لإضافة أداة جديدة: أضف Tool هنا فقط.
final List<Tool> allTools = [
  Tool(
    id: 'discount',
    nameAr: 'حاسبة الخصم',
    nameEn: 'Discount Calculator',
    category: 'calc',
    keywords: ['خصم', 'تخفيض', 'تنزيل', 'discount', 'sale'],
    icon: Icons.percent,
    builder: (_) => const DiscountPage(),
  ),
];
