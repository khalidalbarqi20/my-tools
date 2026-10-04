import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/num_parse.dart';
import 'currency_logic.dart';
import 'currency_service.dart';

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});
  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  final _c = TextEditingController(text: '1');
  RatesSnapshot? _snap;
  bool _loading = true, _refreshFailed = false;
  String _from = 'sar', _to = 'usd';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final cached = await CurrencyService.loadCached();
    if (!mounted) return;
    setState(() => _snap = cached);
    final old = cached == null ||
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
      _refreshFailed = false;
    });
    final fresh = await CurrencyService.fetchFresh();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (fresh != null) {
        _snap = fresh;
      } else {
        _refreshFailed = true;
      }
    });
  }

  String _money(double v) {
    final d = v.abs() >= 1 ? 2 : 6;
    var s = v.toStringAsFixed(d);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  Widget _drop(String label, String value, List<CurrencyInfo> items,
      ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final i in items)
          DropdownMenuItem(value: i.code, child: Text(currencyName(i.code))),
      ],
      onChanged: (v) => onChanged(v ?? value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = _snap;
    final now = DateTime.now();
    final items = s?.available ?? const <CurrencyInfo>[];
    if (items.isNotEmpty) {
      if (!items.any((i) => i.code == _from)) _from = items.first.code;
      if (!items.any((i) => i.code == _to)) {
        _to = items.length > 1 ? items[1].code : items.first.code;
      }
    }
    final v = parseNum(_c.text);
    String? err;
    double? res;
    if (s != null && _c.text.trim().isNotEmpty) {
      if (v == null) {
        err = 'أدخل رقمًا صحيحًا';
      } else if (v < 0) {
        err = 'أدخل مبلغًا موجبًا';
      } else {
        res = convertCurrency(v, _from, _to, s);
        if (res == null) err = 'القيمة كبيرة جدًا';
      }
    }
    final line = (res == null || v == null)
        ? ''
        : '${_money(v)} ${_from.toUpperCase()} = ${_money(res)} ${_to.toUpperCase()}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحويل العملات'),
        actions: [
          IconButton(
            tooltip: 'تحديث الأسعار',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (s == null && !_loading) ...[
            const SizedBox(height: 24),
            Text(
              'لا توجد أسعار محفوظة، وتعذّر تحميلها الآن. '
              'تأكد من اتصالك بالإنترنت ثم حاول مرة أخرى.',
              style: t.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
          ],
          if (s != null) ...[
            TextField(
              controller: _c,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ'),
            ),
            const SizedBox(height: 12),
            _drop('من', _from, items, (c) => setState(() => _from = c)),
            Center(
              child: IconButton(
                tooltip: 'تبديل',
                icon: const Icon(Icons.swap_vert),
                onPressed: () => setState(() {
                  final x = _from;
                  _from = _to;
                  _to = x;
                }),
              ),
            ),
            _drop('إلى', _to, items, (c) => setState(() => _to = c)),
            const SizedBox(height: 20),
            if (err != null)
              Text(err, style: TextStyle(color: t.colorScheme.error)),
            if (res != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: t.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  SelectableText(_money(res),
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(currencyName(_to)),
                ]),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: line));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('تم النسخ')));
                  },
                  child: const Text('نسخ النتيجة'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'تاريخ الأسعار: ${s.apiDate.isEmpty ? 'غير معروف' : s.apiDate}\n'
              'آخر تحديث على جهازك: ${ageLabel(s.fetchedAt, now)}',
              style: t.textTheme.bodySmall
                  ?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
            if (_refreshFailed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'تعذّر تحديث الأسعار، والمعروض آخر أسعار محفوظة.',
                  style: TextStyle(color: t.colorScheme.error),
                ),
              ),
            if (isStale(s, now))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'الأسعار قديمة، فقد لا تطابق السوق الآن.',
                  style: TextStyle(color: t.colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'أسعار إرشادية تُحدَّث يوميًا وليست أسعارًا لحظية، '
                'وقد تختلف عن أسعار البنوك ومحلات الصرافة.',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
