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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: tone.fg.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(category.icon, color: tone.fg, size: 24),
              ),
              const SizedBox(height: 6),
              Text(category.nameAr,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: tone.text, height: 1.2)),
              Text('$count',
                  style: t.textTheme.labelSmall
                      ?.copyWith(color: tone.text.withValues(alpha: 0.75))),
            ],
          ),
        ),
      ),
    );
  }
}
