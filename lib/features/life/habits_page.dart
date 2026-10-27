import 'package:flutter/material.dart';
import 'life_logic.dart';
import 'life_store.dart';

const _k = 'life_habits_v1';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});
  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  List<Habit> _all = [];
  final _c = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadList(_k).then((l) {
      if (mounted) setState(() => _all = [for (final m in l) Habit.fromJson(m)]);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() => saveList(_k, [for (final h in _all) h.toJson()]);

  void _add() {
    final s = _c.text.trim();
    if (s.isEmpty) return;
    setState(() => _all.add(Habit(newId(), s, {})));
    _c.clear();
    _save();
  }

  void _toggle(Habit h, DateTime d) {
    final k = dayKey(d);
    setState(() => h.days.contains(k) ? h.days.remove(k) : h.days.add(k));
    _save();
  }

  Future<void> _confirmDelete(Habit h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('حذف «${h.name}»؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _all.removeWhere((x) => x.id == h.id));
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const names = ['إ', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']; // الاثنين..الأحد
    return Scaffold(
      appBar: AppBar(title: const Text('عاداتي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(
            child: TextField(
                controller: _c,
                onSubmitted: (_) => _add(),
                decoration: const InputDecoration(hintText: 'عادة جديدة (مثال: قراءة ١٠ صفحات)')),
          ),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
        ]),
        const SizedBox(height: 12),
        if (_all.isEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text('ما أضفت عادات بعد.',
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
        for (final h in _all)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(h.name, style: t.textTheme.titleMedium)),
                  Text('🔥 ${habitStreak(h.days, today)}'),
                  IconButton(
                      onPressed: () => _confirmDelete(h), icon: const Icon(Icons.delete_outline)),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  for (var i = 6; i >= 0; i--)
                    Builder(builder: (_) {
                      final d = today.subtract(Duration(days: i));
                      final on = h.days.contains(dayKey(d));
                      return InkWell(
                        onTap: () => _toggle(h, d),
                        borderRadius: BorderRadius.circular(20),
                        child: Column(children: [
                          Text(names[d.weekday - 1], style: t.textTheme.labelSmall),
                          const SizedBox(height: 4),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: on ? cs.primary : cs.surfaceContainerHighest,
                            child: on
                                ? Icon(Icons.check, size: 18, color: cs.onPrimary)
                                : Text('${d.day}', style: t.textTheme.labelSmall),
                          ),
                        ]),
                      );
                    }),
                ]),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text('اضغط على اليوم لتحديده أو إلغائه. 🔥 = أيام متتالية.',
              style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ]),
    );
  }
}
