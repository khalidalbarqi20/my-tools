import 'package:flutter/material.dart';
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: tool.builder)),
    );
  }
}
