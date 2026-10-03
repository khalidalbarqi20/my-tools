import 'package:flutter/material.dart';
import '../../core/categories.dart';
import '../../theme/app_theme.dart';

String toolsCount(int n) => n == 1
    ? 'أداة واحدة'
    : n == 2
        ? 'أداتان'
        : n <= 10
            ? '$n أدوات'
            : '$n أداة';

class CategoryCard extends StatelessWidget {
  final ToolCategory category;
  final int count;
  final VoidCallback onTap;
  const CategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tone = tonalFor(context, category.id);
    return Material(
      color: tone.bg,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: tone.fg.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(category.icon, color: tone.fg, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.nameAr,
                      style: t.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: tone.fg)),
                  Text(toolsCount(count),
                      style: t.textTheme.bodySmall
                          ?.copyWith(color: tone.fg.withValues(alpha: 0.75))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
