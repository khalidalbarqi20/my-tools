import 'package:flutter/material.dart';
import '../../core/categories.dart';
import '../../core/registry.dart';
import '../../core/tool_tile.dart';

class CategoryPage extends StatelessWidget {
  final ToolCategory category;
  const CategoryPage({super.key, required this.category});
  @override
  Widget build(BuildContext context) {
    final tools = allTools.where((t) => t.category == category.id);
    return Scaffold(
      appBar: AppBar(title: Text(category.nameAr)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [for (final t in tools) ToolTile(tool: t)],
      ),
    );
  }
}
