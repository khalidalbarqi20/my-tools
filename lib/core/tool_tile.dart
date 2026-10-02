import 'package:flutter/material.dart';
import '../storage/prefs.dart';
import 'tool.dart';

class ToolTile extends StatelessWidget {
  final Tool tool;
  const ToolTile({super.key, required this.tool});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(tool.icon),
      title: Text(tool.nameAr),
      subtitle: Text(tool.nameEn),
      trailing: ValueListenableBuilder<List<String>>(
        valueListenable: Prefs.favorites,
        builder: (context, favs, child) {
          final f = favs.contains(tool.id);
          return IconButton(
            tooltip: 'المفضلة',
            icon: Icon(f ? Icons.star : Icons.star_outline,
                color: f ? Colors.amber : null),
            onPressed: () => Prefs.toggleFav(tool.id),
          );
        },
      ),
      onTap: () {
        Prefs.addRecent(tool.id);
        Navigator.push(context, MaterialPageRoute(builder: tool.builder));
      },
    );
  }
}
