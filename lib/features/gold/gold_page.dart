import 'package:flutter/material.dart';
import '../../core/display_card.dart';
import '../../core/fmt.dart';
import '../../core/num_parse.dart';
import '../currency/currency_logic.dart';
import '../currency/currency_service.dart';
import 'gold_logic.dart';

class GoldPage extends StatefulWidget {
  const GoldPage({super.key});
  @override
  State<GoldPage> createState() => _GoldPageState();
}

class _GoldPageState extends State<GoldPage> {
  RatesSnapshot? _snap;
  bool _loading = true, _failed = false;
  String _cur = 'sar';
  int _karat = 21;
  final _w = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _w.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final cached = await CurrencyService.loadCached();
    if (!mounted) return;
    setState(() => _snap = cached);
    final old = cached == null ||
        goldOunceUsd(cached) == null ||
        DateTime.now().difference(cached.fetchedAt).inHours >= 6;
    if (old) {
      await _refresh();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final fresh = await CurrencyService.fetchFresh();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (fresh != null) {
        _snap = fresh;
      } else {
        _failed = true;
      }
    });
  }

  String _m(double v) => fmt(v, v >= 100 ? 2 : 4);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final muted = t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final s = _snap;
    final now = DateTime.now();
    final ok = s != null && goldOunceUsd(s) != null;
    final items = s?.available ?? const <CurrencyInfo>[];
    if (items.isNotEmpty && !items.any((i) => i.code == _cur)) _cur = items.first.code;
    final w = parseNum(_w.text);
    return Scaffold(
      appBar: AppBar(
        title: const Text('سعر الذهب'),
        actions: [
          IconButton(
            tooltip: 'تحديث الأسعار',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_loading) const LinearProgressIndicator(),
        if (!ok && !_loading) ...[
          const SizedBox(height: 24),
          Text(
            'لا توجد أسعار ذهب محفوظة، وتعذّر تحميلها الآن. تأكد من اتصالك بالإنترنت ثم حاول مرة أخرى.',
            style: t.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
        ],
        if (s != null && ok) ...[
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _cur,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'العملة'),
            items: [
              for (final i in items)
                DropdownMenuItem(value: i.code, child: Text(currencyName(i.code))),
            ],
            onChanged: (v) => setState(() => _cur = v ?? _cur),
          ),
          const SizedBox(height: 12),
          DisplayCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('سعر الجرام (ذهب خام)',
                  style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final k in goldKarats)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Expanded(child: Text('عيار $k')),
                    Text(_m(goldGramPrice(s, _cur, k) ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ),
              const Divider(),
              Row(children: [
                const Expanded(child: Text('الأونصة (عيار 24)')),
                Text(_m(goldOuncePrice(s, _cur) ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Expanded(child: Text('الأونصة بالدولار')),
                Text(_m(goldOunceUsd(s) ?? 0)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          DisplayCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('قيمة وزن معيّن',
                  style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _w,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الوزن بالجرام'),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final k in goldKarats)
                  ChoiceChip(
                    label: Text('عيار $k'),
                    selected: _karat == k,
                    onSelected: (_) => setState(() => _karat = k),
                  ),
              ]),
              const SizedBox(height: 10),
              if (w != null && w >= 0)
                Text(
                  'القيمة التقريبية: ${_m(w * (goldGramPrice(s, _cur, _karat) ?? 0))} '
                  '${_cur.toUpperCase()}',
                  style: t.textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                )
              else
                Text('أدخل وزنًا صحيحًا', style: TextStyle(color: cs.error)),
            ]),
          ),
          const SizedBox(height: 16),
          Text(
            'تاريخ الأسعار: ${s.apiDate.isEmpty ? 'غير معروف' : s.apiDate}\n'
            'آخر تحديث على جهازك: ${ageLabel(s.fetchedAt, now)}',
            style: muted,
          ),
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('تعذّر تحديث الأسعار، والمعروض آخر أسعار محفوظة.',
                  style: TextStyle(color: cs.error)),
            ),
          if (isStale(s, now))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('الأسعار قديمة، فقد لا تطابق السوق الآن.', style: TextStyle(color: cs.error)),
            ),
          const SizedBox(height: 12),
          Text(
            'هذه أسعار عالمية مرجعية للذهب الخام تُحدَّث يوميًا وليست أسعارًا لحظية. '
            'سعر البيع في محلات الذهب يختلف عنها بسبب المصنعية والرسوم والضريبة وهامش البائع، '
            'ولا تُعدّ هذه الأداة استشارة مالية.',
            style: muted,
          ),
        ],
      ]),
    );
  }
}
