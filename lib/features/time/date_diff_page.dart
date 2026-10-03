import 'package:flutter/material.dart';
import '../../core/display_card.dart';
import '../../core/num_parse.dart';
import 'time_logic.dart';

class DateDiffPage extends StatefulWidget {
  const DateDiffPage({super.key});
  @override
  State<DateDiffPage> createState() => _DateDiffPageState();
}

class _DateDiffPageState extends State<DateDiffPage> {
  DateTime _a = DateTime.now();
  DateTime _b = DateTime.now().add(const Duration(days: 30));
  DateTime _base = DateTime.now();
  final _days = TextEditingController(text: '30');
  bool _subtract = false;

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: DateTime(2200),
      );

  Widget _dateBtn(String label, DateTime d, ValueChanged<DateTime> on) => Expanded(
        child: OutlinedButton(
          onPressed: () async {
            final x = await _pick(d);
            if (x != null) on(x);
          },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(fmtDate(d), style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final r = dateDiff(_a, _b);
    final n = parseNum(_days.text)?.round();
    final res = n == null ? null : addDays(_base, _subtract ? -n : n);
    final parts = [
      if (r.years > 0) '${r.years} سنة',
      if (r.months > 0) '${r.months} شهر',
      if (r.days > 0 || (r.years == 0 && r.months == 0)) '${r.days} يوم',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('فرق التواريخ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            _dateBtn('من', _a, (x) => setState(() => _a = x)),
            const SizedBox(width: 10),
            _dateBtn('إلى', _b, (x) => setState(() => _b = x)),
          ]),
          const SizedBox(height: 14),
          DisplayCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(parts.join(' و'),
                  style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('الإجمالي: ${r.total} يوم'),
              Text('أي ${r.total ~/ 7} أسبوع و${r.total % 7} يوم'),
              Text('أي ${r.total * 24} ساعة'),
            ]),
          ),
          const SizedBox(height: 32),
          Text('إضافة أو طرح أيام',
              style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            _dateBtn('من تاريخ', _base, (x) => setState(() => _base = x)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _days,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'عدد الأيام'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('إضافة')),
                ButtonSegment(value: true, label: Text('طرح')),
              ],
              selected: {_subtract},
              onSelectionChanged: (s) => setState(() => _subtract = s.first),
            ),
          ),
          const SizedBox(height: 12),
          DisplayCard(
            child: Text(
              res == null
                  ? 'اكتب عدد أيام صحيح'
                  : '${weekdayAr(res)} ${fmtDate(res)}',
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
