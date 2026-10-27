import 'package:flutter/material.dart';
import 'life_logic.dart';
import 'life_store.dart';

const _k = 'life_tasks_v1';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> _all = [];
  int _mode = 1;
  final _c = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadList(_k).then((l) {
      if (mounted) setState(() => _all = [for (final m in l) Task.fromJson(m)]);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() => saveList(_k, [for (final t in _all) t.toJson()]);

  void _add() {
    final s = _c.text.trim();
    if (s.isEmpty) return;
    setState(() => _all.insert(0, Task(newId(), s, false)));
    _c.clear();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final list = filterTasks(_all, _mode);
    final done = _all.where((t) => t.done).length;
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('مهامي'), actions: [
        if (done > 0)
          TextButton(
              onPressed: () {
                setState(() => _all.removeWhere((x) => x.done));
                _save();
              },
              child: const Text('حذف المنجزة')),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _c,
              onSubmitted: (_) => _add(),
              decoration: const InputDecoration(hintText: 'مهمة جديدة'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final e in const [(0, 'الكل'), (1, 'المتبقية'), (2, 'المنجزة')])
            ChoiceChip(label: Text(e.$2), selected: _mode == e.$1, onSelected: (_) => setState(() => _mode = e.$1)),
        ]),
        const SizedBox(height: 8),
        Text('${_all.length - done} متبقية • $done منجزة',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        if (list.isEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text('لا مهام هنا.',
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))),
        for (final k in list)
          Dismissible(
            key: ValueKey(k.id),
            background: Container(color: t.colorScheme.errorContainer),
            onDismissed: (_) {
              setState(() => _all.removeWhere((x) => x.id == k.id));
              _save();
            },
            child: CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: k.done,
              title: Text(k.text,
                  style: TextStyle(
                      decoration: k.done ? TextDecoration.lineThrough : null,
                      color: k.done ? t.colorScheme.onSurfaceVariant : null)),
              onChanged: (v) {
                setState(() => k.done = v ?? false);
                _save();
              },
            ),
          ),
      ]),
    );
  }
}
