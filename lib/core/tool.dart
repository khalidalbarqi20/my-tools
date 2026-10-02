import 'package:flutter/material.dart';

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

  bool matches(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    return nameAr.contains(s) ||
        nameEn.toLowerCase().contains(s) ||
        keywords.any((k) => k.toLowerCase().contains(s));
  }
}
