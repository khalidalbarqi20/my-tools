import 'package:flutter/material.dart';
import '../../core/categories.dart';
import '../../core/registry.dart';
import '../../core/tool.dart';
import '../../core/tool_tile.dart';
import '../../storage/prefs.dart';
import '../../theme/app_theme.dart';
import '../htmlrun/html_runner_page.dart';
import 'category_card.dart';
import 'category_page.dart';

const _popular = [
  'calculator', 'discount', 'pdf_merge', 'img_compress', 'conv_length', 'qr_scan'
];

class _QuickCard extends StatelessWidget {
  final Tool tool;
  const _QuickCard({required this.tool});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tone = tonalFor(context, tool.category);
    return Material(
      color: cardColor(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: softBorder(context)),
      ),
      child: InkWell(
        onTap: () => openTool(context, tool),
        child: SizedBox(
          width: 108,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: tone.bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(tool.icon, color: tone.fg, size: 22),
                ),
                const SizedBox(height: 8),
                Text(tool.nameAr,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sc = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Widget _section(String s) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(s,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      );

  Widget _strip() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: Prefs.recents,
      builder: (context, ids, child) {
        final rec = [
          for (final id in ids) ...allTools.where((t) => t.id == id)
        ];
        final pop = [
          for (final id in _popular) ...allTools.where((t) => t.id == id)
        ];
        final show = rec.isNotEmpty ? rec.take(8).toList() : pop;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _section(rec.isNotEmpty ? 'آخر استخدام' : 'الأكثر استخدامًا'),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: show.length,
              separatorBuilder: (c, i) => const SizedBox(width: 10),
              itemBuilder: (c, i) => _QuickCard(tool: show[i]),
            ),
          ),
        ]);
      },
    );
  }

  Widget _grid() {
    final w = MediaQuery.sizeOf(context).width;
    final cols = gridCols(w);
    final cats = activeCategories();
    final solo = allTools.where((t) => t.isStandalone).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: solo.length + cats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 112,
      ),
      itemBuilder: (c, i) {
        if (i < solo.length) {
          return StandaloneCard(
              tool: solo[i], onTap: () => openTool(context, solo[i]));
        }
        final cat = cats[i - solo.length];
        return CategoryCard(
          category: cat,
          count: allTools.where((t) => t.category == cat.id).length,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => CategoryPage(category: cat))),
        );
      },
    );
  }

  Widget _htmlRunnerCard() {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Material(
        color: cardColor(context),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: softBorder(context)),
        ),
        child: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HtmlRunnerPage())),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.html, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تشغيل صفحة HTML',
                          style: t.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text('افتح ملف HTML أو مشروع ZIP كامل',
                          style: t.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final searching = _q.trim().isNotEmpty;
    final results = allTools.where((x) => x.matches(_q)).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: cs.primary, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.apps_rounded, color: cs.onPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أدواتي اليومية',
                        style: t.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('كل أدواتك في مكان واحد',
                        style: t.textTheme.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
            ),
          ]),
          const SizedBox(height: 20),
          TextField(
            controller: _sc,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن أداة...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _sc.clear();
                        setState(() => _q = '');
                      }),
            ),
          ),
          if (searching) ...[
            const SizedBox(height: 16),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(children: [
                  Icon(Icons.search_off_rounded, size: 48, color: cs.outline),
                  const SizedBox(height: 8),
                  const Text('ما لقينا أداة بهذا الاسم'),
                ]),
              ),
            if (results.isNotEmpty) ToolGrid(tools: results),
          ] else ...[
            _strip(),
            _section('الأقسام'),
            _grid(),
            _htmlRunnerCard(),
          ],
        ],
      ),
    );
  }
}
