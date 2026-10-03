import 'package:flutter/material.dart';
import '../../core/registry.dart';
import '../../core/tool_tile.dart';
import '../../storage/prefs.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      child: ValueListenableBuilder<List<String>>(
        valueListenable: Prefs.favorites,
        builder: (context, ids, child) {
          final tools = [
            for (final id in ids) ...allTools.where((x) => x.id == id)
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text('المفضلة',
                  style: t.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (tools.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: Column(children: [
                    Icon(Icons.star_outline_rounded,
                        size: 56, color: t.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('ما أضفت أي أداة للمفضلة',
                        style: t.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('اضغط النجمة بجانب أي أداة لتظهر هنا',
                        style: t.textTheme.bodyMedium
                            ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  ]),
                )
              else
                for (final x in tools) ToolTile(tool: x),
            ],
          );
        },
      ),
    );
  }
}
