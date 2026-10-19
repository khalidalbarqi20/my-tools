import 'package:flutter/material.dart';
import '../ads/ad_shell.dart';
import '../ads/ads.dart';
import '../storage/prefs.dart';
import '../theme/app_theme.dart';
import 'tool.dart';

void openTool(BuildContext context, Tool tool) {
  Prefs.addRecent(tool.id);
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (c) => AdShell(toolId: tool.id, child: tool.builder(c))),
  ).then((_) => Ads.onToolClosed(tool.id));
}

class ToolTile extends StatelessWidget {
  final Tool tool;
  const ToolTile({super.key, required this.tool});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tone = tonalFor(context, tool.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cardColor(context),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: softBorder(context)),
        ),
        child: InkWell(
          onTap: () => openTool(context, tool),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: tone.bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(tool.icon, color: tone.fg, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tool.nameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(tool.nameEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodySmall
                              ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    ]),
              ),
              ValueListenableBuilder<List<String>>(
                valueListenable: Prefs.favorites,
                builder: (context, favs, child) {
                  final f = favs.contains(tool.id);
                  return IconButton(
                    tooltip: 'المفضلة',
                    icon: Icon(
                        f ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: f ? Colors.amber : t.colorScheme.outline),
                    onPressed: () => Prefs.toggleFav(tool.id),
                  );
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// عدد أعمدة الشبكة: 4 على الجوال، وأكثر على الشاشات الأوسع.
int gridCols(double w) => w >= 900 ? 6 : (w >= 600 ? 5 : 4);

/// أيقونة مربعة للأداة مع اسمها تحتها ونجمة المفضلة في الزاوية.
class ToolSquare extends StatelessWidget {
  final Tool tool;
  const ToolSquare({super.key, required this.tool});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tone = tonalFor(context, tool.category);
    return Tooltip(
      message: tool.nameAr,
      child: Material(
        color: cardColor(context),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: softBorder(context)),
        ),
        child: Stack(children: [
          Positioned.fill(
            child: InkWell(
              onTap: () => openTool(context, tool),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: tone.bg, borderRadius: BorderRadius.circular(12)),
                      child: Icon(tool.icon, color: tone.fg, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(tool.nameAr,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700, height: 1.25)),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: ValueListenableBuilder<List<String>>(
              valueListenable: Prefs.favorites,
              builder: (context, favs, child) {
                final f = favs.contains(tool.id);
                return InkResponse(
                  radius: 18,
                  onTap: () => Prefs.toggleFav(tool.id),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                        f ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 17,
                        color: f ? Colors.amber : t.colorScheme.outline),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

/// شبكة أدوات مربعة (4 في الصف على الجوال) تُوضع داخل ListView.
class ToolGrid extends StatelessWidget {
  final List<Tool> tools;
  const ToolGrid({super.key, required this.tools});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: tools.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCols(MediaQuery.sizeOf(context).width),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 104,
      ),
      itemBuilder: (c, i) => ToolSquare(tool: tools[i]),
    );
  }
}
