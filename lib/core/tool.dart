import 'package:flutter/material.dart';
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

  bool matches(String q) => fuzzyMatch(q, [nameAr, nameEn, ...keywords]);
}
