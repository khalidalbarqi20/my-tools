import 'package:flutter/material.dart';
import '../../core/registry.dart';
import '../../core/tool_tile.dart';
import '../../storage/prefs.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<List<String>>(
        valueListenable: Prefs.favorites,
        builder: (context, ids, child) {
          final tools = [
            for (final id in ids) ...allTools.where((t) => t.id == id)
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Text('المفضلة', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              if (tools.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('اضغط ⭐ بجانب أي أداة لتظهر هنا')))
              else
                for (final t in tools) ToolTile(tool: t),
            ],
          );
        },
      ),
    );
  }
}
