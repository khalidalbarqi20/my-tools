import 'package:flutter/material.dart';
import '../../core/registry.dart';
import '../../core/tool_tile.dart';
import '../../storage/prefs.dart';

class RecentsSection extends StatelessWidget {
  const RecentsSection({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: Prefs.recents,
      builder: (context, ids, child) {
        final tools = [
          for (final id in ids) ...allTools.where((t) => t.id == id)
        ].take(4).toList();
        if (tools.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('آخر استخدام',
                  style: Theme.of(context).textTheme.titleMedium)),
          for (final t in tools) ToolTile(tool: t),
          const SizedBox(height: 20),
        ]);
      },
    );
  }
}
