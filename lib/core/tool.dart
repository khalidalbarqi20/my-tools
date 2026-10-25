import 'package:flutter/material.dart';
import 'categories.dart' show categories;
import 'search.dart';

/// قسم خاص: الأداة المستقلة لا تتبع أي تصنيف وتظهر مع الأقسام في الرئيسية.
const kStandalone = '_standalone';

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

  bool get isStandalone => category == kStandalone;

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
