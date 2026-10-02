import 'package:flutter/material.dart';
import '../../core/categories.dart';
import '../../core/registry.dart';
import 'category_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Text('التصنيفات', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          for (final c in activeCategories())
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(c.icon),
              title: Text(c.nameAr),
              subtitle: Text('${allTools.where((t) => t.category == c.id).length} أدوات'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CategoryPage(category: c))),
            ),
        ],
      ),
    );
  }
}
