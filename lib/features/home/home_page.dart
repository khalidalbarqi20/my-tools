import 'package:flutter/material.dart';
import '../../core/categories.dart';
import '../../core/registry.dart';
import '../../core/tool_tile.dart';
import 'category_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _q = '';

  Widget _title(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(s, style: Theme.of(context).textTheme.titleMedium));

  Widget _grid() {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 900 ? 6 : (w >= 600 ? 4 : 3);
    final cs = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        for (final c in activeCategories())
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CategoryPage(category: c))),
            child: Ink(
              decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(18)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(c.icon, color: cs.onSecondaryContainer),
                const SizedBox(height: 8),
                Text(c.nameAr, style: TextStyle(color: cs.onSecondaryContainer)),
              ]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final searching = _q.trim().isNotEmpty;
    final results = allTools.where((x) => x.matches(_q)).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Text('أدواتي اليومية',
              style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('كل أدواتك في مكان واحد',
              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          SearchBar(
            elevation: const WidgetStatePropertyAll(0),
            hintText: 'ابحث عن أداة...',
            leading: const Icon(Icons.search),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 20),
          if (searching) ...[
            if (results.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('ما لقينا أداة بهذا الاسم'))),
            for (final x in results) ToolTile(tool: x),
          ] else ...[
            _title('الأقسام'),
            _grid(),
            const SizedBox(height: 20),
            _title('كل الأدوات'),
            for (final x in allTools) ToolTile(tool: x),
          ],
        ],
      ),
    );
  }
}
