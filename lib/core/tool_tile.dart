import 'package:flutter/material.dart';
import '../storage/prefs.dart';
import '../theme/app_theme.dart';
import 'tool.dart';

void openTool(BuildContext context, Tool tool) {
  Prefs.addRecent(tool.id);
  Navigator.push(context, MaterialPageRoute(builder: tool.builder));
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
