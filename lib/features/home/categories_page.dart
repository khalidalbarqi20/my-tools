import 'package:flutter/material.dart';
import '../../core/categories.dart';
import '../../core/registry.dart';
import 'category_card.dart';
import 'category_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
    final cats = activeCategories();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('التصنيفات',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: cats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 132,
            ),
            itemBuilder: (c, i) {
              final cat = cats[i];
              return CategoryCard(
                category: cat,
                count: allTools.where((t) => t.category == cat.id).length,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CategoryPage(category: cat))),
              );
            },
          ),
        ],
      ),
    );
  }
}
