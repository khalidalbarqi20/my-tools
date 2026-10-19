import 'package:flutter/material.dart';
import 'categories.dart' show categories;
import 'search.dart';

class Tool {
  final String id, nameAr, nameEn, category;
  final List<String> keywords;
  final IconData icon;
  final WidgetBuilder builder;
  const Tool({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.keywords,
    required this.icon,
    required this.builder,
  });

  /// البحث بالاسم أو الكلمات المفتاحية أو اسم القسم (فيظهر قسم «السيارة» كاملًا عند كتابة «سيارة»).
  bool matches(String q) {
    final cat = categories.where((c) => c.id == category);
    return fuzzyMatch(q, [
      nameAr,
      nameEn,
      ...keywords,
      for (final c in cat) ...[c.nameAr, c.nameEn],
    ]);
  }
}
