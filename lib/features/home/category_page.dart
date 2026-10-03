import 'package:flutter/material.dart';
import '../../core/categories.dart';
import '../../core/registry.dart';
import '../../core/tool_tile.dart';
import 'category_card.dart' show toolsCount;

class CategoryPage extends StatelessWidget {
  final ToolCategory category;
  const CategoryPage({super.key, required this.category});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tools = allTools.where((x) => x.category == category.id).toList();
    return Scaffold(
      appBar: AppBar(title: Text(category.nameAr)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(toolsCount(tools.length),
                style: t.textTheme.bodyMedium
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
          for (final x in tools) ToolTile(tool: x),
        ],
      ),
    );
  }
}
