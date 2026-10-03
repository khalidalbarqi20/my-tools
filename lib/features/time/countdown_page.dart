import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/display_card.dart';
import 'time_logic.dart';

class _Ev {
  final String title;
  final DateTime at;
  _Ev(this.title, this.at);
  String encode() => '${at.millisecondsSinceEpoch}|$title';
  static _Ev? decode(String s) {
    final i = s.indexOf('|');
    if (i <= 0) return null;
    final ms = int.tryParse(s.substring(0, i));
    if (ms == null) return null;
    return _Ev(s.substring(i + 1), DateTime.fromMillisecondsSinceEpoch(ms));
  }
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _title = TextEditingController();
  late DateTime _at = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (d != null) {
      setState(() => _at = DateTime(d.year, d.month, d.day, _at.hour, _at.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_at));
    if (t != null) {
      setState(() => _at = DateTime(_at.year, _at.month, _at.day, t.hour, t.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مناسبة جديدة',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'اسم المناسبة')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(fmtDate(_at))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(fmtTime(_at))),
            ),
          ]),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(
                context,
                _Ev(_title.text.trim().isEmpty ? 'مناسبتي' : _title.text.trim(), _at)),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});
  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  SharedPreferences? _p;
  List<_Ev> _ev = [];
  Timer? _t;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      _p = p;
      final l = (p.getStringList('countdowns') ?? [])
          .map(_Ev.decode)
          .whereType<_Ev>()
          .toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      if (mounted) setState(() => _ev = l);
    });
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _ev.isNotEmpty) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _save() => _p?.setStringList('countdowns', [for (final e in _ev) e.encode()]);

  Future<void> _add() async {
    final e = await showModalBottomSheet<_Ev>(
        context: context, isScrollControlled: true, builder: (_) => const _AddSheet());
    if (e == null || !mounted) return;
    setState(() => _ev = [..._ev, e]..sort((a, b) => a.at.compareTo(b.at)));
    _save();
  }

  Widget _unit(String n, String label, Color? c) => Expanded(
        child: Column(children: [
          Text(n,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: c,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );

  Widget _card(_Ev e) {
    final t = Theme.of(context);
    final diff = e.at.difference(DateTime.now());
    final past = diff.isNegative;
    final b = breakdown(diff);
    final c = past ? t.colorScheme.outline : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DisplayCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title,
                    style: t.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text('${fmtDate(e.at)}  ${fmtTime(e.at)}',
                    style: t.textTheme.bodySmall
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ]),
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() => _ev = _ev.where((x) => x != e).toList());
                _save();
              },
            ),
          ]),
          const SizedBox(height: 12),
          if (past)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('مضى على المناسبة',
                  style: t.textTheme.bodySmall?.copyWith(color: c)),
            ),
          Row(children: [
            _unit('${b.days}', 'يوم', c),
            _unit(p2(b.hours), 'ساعة', c),
            _unit(p2(b.minutes), 'دقيقة', c),
            _unit(p2(b.seconds), 'ثانية', c),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('عد تنازلي لمناسبة')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مناسبة')),
          const SizedBox(height: 16),
          if (_ev.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(children: [
                Icon(Icons.event_outlined, size: 52, color: t.colorScheme.outline),
                const SizedBox(height: 8),
                const Text('ما أضفت أي مناسبة بعد'),
              ]),
            ),
          for (final e in _ev) _card(e),
        ],
      ),
    );
  }
}
