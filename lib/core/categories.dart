import 'package:flutter/material.dart';
import 'registry.dart';

class ToolCategory {
  final String id, nameAr, nameEn;
  final IconData icon;
  const ToolCategory(this.id, this.nameAr, this.nameEn, this.icon);
}

const categories = [
  ToolCategory('calc', 'الحسابات', 'Calculators', Icons.calculate_outlined),
  ToolCategory('convert', 'التحويلات', 'Converters', Icons.swap_horiz),
  ToolCategory('pdf', 'PDF', 'PDF', Icons.picture_as_pdf_outlined),
  ToolCategory('image', 'الصور', 'Images', Icons.image_outlined),
  ToolCategory('qr', 'QR', 'QR', Icons.qr_code_2),
  ToolCategory('time', 'الوقت', 'Time', Icons.timer_outlined),
  ToolCategory('text', 'النصوص', 'Text', Icons.text_fields),
  ToolCategory('device', 'الجهاز', 'Device', Icons.phone_android),
  ToolCategory('random', 'عشوائي', 'Random', Icons.casino_outlined),
];

/// الأقسام التي فيها أدوات فقط.
List<ToolCategory> activeCategories() =>
    categories.where((c) => allTools.any((t) => t.category == c.id)).toList();
