import 'package:flutter/material.dart';
import '../remote/remote_model.dart';
import '../remote/remote_store.dart';
import 'registry.dart';

class ToolCategory {
  final String id, nameAr, nameEn;
  final IconData icon;
  const ToolCategory(this.id, this.nameAr, this.nameEn, this.icon);
}

const categories = [
  ToolCategory('calc', 'الحسابات', 'Calculators', Icons.calculate_outlined),
  ToolCategory('math', 'الرياضيات', 'Math', Icons.functions),
  ToolCategory('convert', 'التحويلات', 'Converters', Icons.swap_horiz),
  ToolCategory('pdf', 'PDF', 'PDF', Icons.picture_as_pdf_outlined),
  ToolCategory('image', 'الصور', 'Images', Icons.image_outlined),
  ToolCategory('qr', 'QR', 'QR', Icons.qr_code_2),
  ToolCategory('geo', 'الهندسة', 'Geometry', Icons.square_foot),
  ToolCategory('science', 'العلوم والإحصاء', 'Science & Statistics', Icons.science_outlined),
  ToolCategory('car', 'السيارة', 'Car', Icons.directions_car_outlined),
  ToolCategory('home', 'المنزل', 'Home', Icons.home_outlined),
  ToolCategory('time', 'الوقت', 'Time', Icons.timer_outlined),
  ToolCategory('text', 'النصوص', 'Text', Icons.text_fields),
  ToolCategory('device', 'الجهاز', 'Device', Icons.phone_android),
  ToolCategory('random', 'عشوائي', 'Random', Icons.casino_outlined),
];

const _iconKeys = <String, IconData>{
  'calculate': Icons.calculate_outlined,
  'swap': Icons.swap_horiz,
  'pdf': Icons.picture_as_pdf_outlined,
  'image': Icons.image_outlined,
  'qr': Icons.qr_code_2,
  'time': Icons.timer_outlined,
  'text': Icons.text_fields,
  'device': Icons.phone_android,
  'random': Icons.casino_outlined,
  'money': Icons.attach_money,
  'star': Icons.star_outline,
  'build': Icons.build_outlined,
  'science': Icons.science_outlined,
  'game': Icons.sports_esports_outlined,
  'school': Icons.school_outlined,
  'shop': Icons.shopping_bag_outlined,
  'home': Icons.home_outlined,
  'heart': Icons.favorite_border,
  'travel': Icons.flight_outlined,
  'book': Icons.menu_book_outlined,
  'music': Icons.music_note_outlined,
  'map': Icons.map_outlined,
  'chat': Icons.chat_bubble_outline,
  'settings': Icons.settings_outlined,
  'geo': Icons.square_foot,
  'car': Icons.directions_car_outlined,
  'math': Icons.functions,
  'apps': Icons.apps,
};

IconData iconForKey(String key, [IconData fallback = Icons.apps]) =>
    _iconKeys[key] ?? fallback;

/// يطبّق إعدادات لوحة الإدارة على الأقسام: ترتيب، أسماء، إخفاء، وأقسام جديدة.
List<ToolCategory> applyCategoryConfig(List<ToolCategory> base, RemoteConfig? cfg) {
  if (cfg == null || cfg.categories.isEmpty) return base;
  final byId = {for (final c in base) c.id: c};
  final seen = <String>{};
  final out = <ToolCategory>[];
  for (final o in cfg.categories) {
    if (!seen.add(o.id)) continue;
    if (!o.visible) continue;
    final b = byId[o.id];
    out.add(ToolCategory(o.id, o.nameAr, o.nameEn, iconForKey(o.icon, b?.icon ?? Icons.apps)));
  }
  for (final c in base) {
    if (!seen.contains(c.id)) out.add(c);
  }
  return out;
}

/// الأقسام التي فيها أدوات فقط.
List<ToolCategory> activeCategories() {
  final tools = allTools;
  return applyCategoryConfig(categories, RemoteStore.config.value)
      .where((c) => tools.any((t) => t.category == c.id))
      .toList();
}
