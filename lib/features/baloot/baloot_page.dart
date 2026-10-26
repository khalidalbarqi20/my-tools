import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'baloot_logic.dart';

const _kHist = 'baloot_hist';
const _kNames = 'baloot_names';
const _win = 152;

int _int(String s) => int.tryParse(s.trim()) ?? 0;

class BalootPage extends StatefulWidget {
  const BalootPage({super.key});
  @override
  State<BalootPage> createState() => _BalootPageState();
}

class _BalootPageState extends State<BalootPage> {
  SharedPreferences? _p;
  List<List<int>> _h = [];
  List<String> _n = ['لنا', 'لهم'];
  final _ia = TextEditingController();
  final _ib = TextEditingController();
  final _fa = FocusNode();
  final _fb = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ia.dispose();
    _ib.dispose();
    _fa.dispose();
    _fb.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final h = p.getStringList(_kHist) ?? [];
      final n = p.getStringList(_kNames);
      if (!mounted) return;
      setState(() {
        _p = p;
        _h = [
          for (final s in h)
            [for (final x in s.split(',')) int.tryParse(x) ?? 0]
        ].where((r) => r.length == 2).toList();
        if (n != null && n.length == 2) _n = n;
      });
    } catch (_) {}
  }

  void _save() {
    _p?.setStringList(_kHist, [for (final r in _h) '${r[0]},${r[1]}']);
  }

  List<int> get _tot {
    var a = 0, b = 0;
    for (final r in _h) {
      a += r[0];
      b += r[1];
    }
    return [a, b];
  }

  void _addRound(int a, int b) {
    if (a == 0 && b == 0) return;
    setState(() => _h.add([a, b]));
    _ia.clear();
    _ib.clear();
    _save();
    _checkWin();
  }

  void _checkWin() {
    final t = _tot;
    if ((t[0] >= _win || t[1] >= _win) && t[0] != t[1]) {
      HapticFeedback.heavyImpact();
      final loser = t[0] > t[1] ? _n[1] : _n[0];
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('قامت على $loser', textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
                onPressed: () {
                  Navigator.pop(c);
                  _reset();
                },
                child: const Text('صكة جديدة')),
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('إغلاق')),
          ],
        ),
      );
    }
  }

  void _reset() {
    setState(() => _h = []);
    _save();
  }

  Future<void> _newGame() async {
    if (_h.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تبدأ لعبة جديدة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('لا')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('نعم')),
        ],
      ),
    );
    if (ok == true) _reset();
  }

  void _undo() {
    if (_h.isEmpty) return;
    setState(() => _h.removeLast());
    _save();
  }

  Future<void> _editNames() async {
    final c0 = TextEditingController(text: _n[0]);
    final c1 = TextEditingController(text: _n[1]);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('أسماء الفرق'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: c0,
              decoration: const InputDecoration(labelText: 'الفريق الأول')),
          const SizedBox(height: 12),
          TextField(
              controller: c1,
              decoration: const InputDecoration(labelText: 'الفريق الثاني')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('حفظ')),
        ],
      ),
    );
    final a = c0.text.trim(), b = c1.text.trim();
    c0.dispose();
    c1.dispose();
    if (ok == true) {
      setState(() => _n = [a.isEmpty ? 'لنا' : a, b.isEmpty ? 'لهم' : b]);
      _p?.setStringList(_kNames, _n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final tot = _tot;
    final a = tot[0], b = tot[1];
    String banner = '';
    var bannerBad = false;
    if (a >= _win || b >= _win) {
      if (a == b) {
        banner = 'تعادل ($a) — لازم صكة زيادة';
        bannerBad = true;
      } else {
        banner = 'الفوز ${a > b ? _n[0] : _n[1]} 🎉';
      }
    }
    Widget score(String name, int v) => Expanded(
          child: Column(children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text('$v',
                style: t.textTheme.displayLarge
                    ?.copyWith(fontWeight: FontWeight.w300)),
          ]),
        );
    Widget input(TextEditingController c, FocusNode fn, String label,
            TextEditingController o, FocusNode ofn) =>
        Expanded(
          child: TextField(
            controller: c,
            focusNode: fn,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: t.textTheme.headlineMedium,
            onChanged: (v) {
              if (v.length >= 2 && o.text.isEmpty) ofn.requestFocus();
            },
            decoration: InputDecoration(labelText: label, hintText: '0'),
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة البلوت'),
        actions: [
          IconButton(
              tooltip: 'أسماء الفرق',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editNames),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(children: [score(_n[0], a), score(_n[1], b)]),
            SizedBox(
              height: 32,
              child: Center(
                child: Text(banner,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: bannerBad ? cs.error : Colors.green)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                input(_ia, _fa, _n[0], _ib, _fb),
                const SizedBox(width: 12),
                SizedBox(
                  width: 88,
                  height: 88,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        fixedSize: const Size(88, 88)),
                    onPressed: () => _addRound(_int(_ia.text), _int(_ib.text)),
                    child: const Text('سجل',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                input(_ib, _fb, _n[1], _ia, _fa),
              ],
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              TextButton(
                  onPressed: _newGame,
                  child: const Text('صكة جديدة',
                      style: TextStyle(color: Colors.green, fontSize: 17))),
              TextButton(
                  onPressed: _undo,
                  child: Text('تراجع',
                      style: TextStyle(color: cs.error, fontSize: 17))),
            ]),
            for (final r in _h.reversed)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: cs.outlineVariant))),
                child: Row(children: [
                  Expanded(
                      child: Text('${r[0]}',
                          textAlign: TextAlign.center,
                          style: t.textTheme.titleLarge)),
                  Expanded(
                      child: Text('${r[1]}',
                          textAlign: TextAlign.center,
                          style: t.textTheme.titleLarge)),
                ]),
              ),
            const SizedBox(height: 12),
            _CalcCard(
                kind: BalootKind.sun, names: _n, onRegister: _addRound),
            _CalcCard(
                kind: BalootKind.hakam, names: _n, onRegister: _addRound),
          ],
        ),
      ),
    );
  }
}

class _CalcCard extends StatefulWidget {
  final BalootKind kind;
  final List<String> names;
  final void Function(int, int) onRegister;
  const _CalcCard(
      {required this.kind, required this.names, required this.onRegister});
  @override
  State<_CalcCard> createState() => _CalcCardState();
}

class _CalcCardState extends State<_CalcCard> {
  int _buy = 0;
  int _anchor = -1;
  final _f = [TextEditingController(), TextEditingController()];
  late final List<List<int>> _proj = [
    List.filled(balootProjectNames(widget.kind).length, 0),
    List.filled(balootProjectNames(widget.kind).length, 0),
  ];
  final _bal = [0, 0];
  BalootResult? _res;
  String? _msg;

  @override
  void dispose() {
    for (final c in _f) {
      c.dispose();
    }
    super.dispose();
  }

  TeamInput _team(int i) => TeamInput(List.of(_proj[i]), _bal[i]);

  void _setBuyer(int i) {
    if (i == _buy) return;
    final t = _f[0].text;
    _f[0].text = _f[1].text;
    _f[1].text = t;
    if (_anchor >= 0) _anchor = 1 - _anchor;
    setState(() {
      _buy = i;
      _res = null;
      _msg = null;
    });
    _refresh();
  }

  void _refresh() {
    final total = balootTotal(widget.kind);
    if (_anchor < 0) return;
    final x = int.tryParse(_f[_anchor].text.trim());
    final o = _f[1 - _anchor];
    if (x == null) {
      o.text = '';
    } else {
      o.text = (total - x >= 0) ? '${total - x}' : '';
    }
    setState(() {});
  }

  void _typed(int i) {
    _anchor = i;
    _refresh();
  }

  void _calc() {
    _refresh();
    final f0 = int.tryParse(_f[0].text.trim());
    final total = balootTotal(widget.kind);
    if (f0 == null) {
      setState(() {
        _res = null;
        _msg = _anchor < 0
            ? 'اكتب نقاط المشتري أو الخصم أولاً'
            : 'النقاط أكبر من إجمالي الأوراق ($total)';
      });
      return;
    }
    final r = balootEval(widget.kind, _buy, f0, _team(0), _team(1));
    setState(() {
      if (r.outOfRange) {
        _res = null;
        _msg = 'نقاط الأوراق لازم تكون بين 0 و ${r.total}';
      } else {
        _res = r;
        _msg = null;
      }
    });
  }

  Widget _pick(String label, int v, int max, ValueChanged<int> on) => Expanded(
        child: Column(children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
          DropdownButton<int>(
            isExpanded: true,
            value: v,
            items: [
              for (var i = 0; i <= max; i++)
                DropdownMenuItem(
                    value: i, child: Center(child: Text('$i')))
            ],
            onChanged: (x) {
              if (x == null) return;
              on(x);
              setState(() {
                _res = null;
                _msg = null;
              });
              _refresh();
            },
          ),
        ]),
      );

  Widget _projects(int team) {
    final names = balootProjectNames(widget.kind);
    final hasBal = balootHasBalot(widget.kind);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('مشاريع ${widget.names[team]}',
            style: Theme.of(context).textTheme.bodyMedium),
        Row(children: [
          for (var j = 0; j < names.length; j++)
            _pick(names[j], _proj[team][j], 4,
                (x) => _proj[team][j] = x),
          if (hasBal)
            _pick('بلوت', _bal[team], 1, (x) => _bal[team] = x),
        ]),
      ]),
    );
  }

  String _pointsLine(String who, int pts, int cards) {
    final extra = pts - cards;
    final tail = extra != 0 ? ' + $extra مشاريع' : '';
    return 'نقاط $who: $pts ($cards أوراق$tail)';
  }

  Widget _line(String s) => Text(s, style: const TextStyle(height: 1.8));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final k = widget.kind;
    final n = widget.names;
    final by = _buy;
    final pi = balootGameTotal(k, _team(0), _team(1));
    final total = balootTotal(k);
    String? sum;
    final f0 = int.tryParse(_f[0].text.trim());
    if (_anchor >= 0 && f0 != null) {
      final ev = balootEval(k, by, f0, _team(0), _team(1));
      if (!ev.outOfRange) {
        sum = 'المجموع مع المشاريع — ${n[by]}: ${ev.points[by]} | '
            '${n[1 - by]}: ${ev.points[1 - by]}';
      }
    }
    final r = _res;
    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(balootTitle(k),
            style: t.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('المشتري')),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 0, label: Text(n[0])),
              ButtonSegment(value: 1, label: Text(n[1])),
            ],
            selected: {by},
            onSelectionChanged: (s) => _setBuyer(s.first),
          ),
          const SizedBox(height: 10),
          Center(
              child: Text('إجمالي اللعب: $pi نقطة',
                  style: t.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700))),
          const SizedBox(height: 10),
          TextField(
            controller: _f[0],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _typed(0),
            decoration: InputDecoration(
                labelText: 'نقاط ${n[by]} (المشتري) من الأوراق (من $total)',
                hintText: '0'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _f[1],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _typed(1),
            decoration: InputDecoration(
                labelText: 'نقاط ${n[1 - by]} (الخصم) — تظهر تلقائياً',
                hintText: '0'),
          ),
          if (sum != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(child: Text(sum, textAlign: TextAlign.center))),
          _projects(0),
          _projects(1),
          const SizedBox(height: 12),
          FilledButton(onPressed: _calc, child: const Text('احسب')),
          if (_msg != null)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_msg!, style: TextStyle(color: cs.error))),
          if (r != null) ...[
            const SizedBox(height: 10),
            _line('إجمالي اللعب: ${r.total} نقطة'),
            _line(_pointsLine('${n[by]} (المشتري)', r.points[by], r.cards[by])),
            _line(_pointsLine('${n[1 - by]} (الخصم)', r.points[1 - by], r.cards[1 - by])),
            _line('الأعداد — ${n[0]}: ${r.counts[0]} | ${n[1]}: ${r.counts[1]}'),
            Text(
              r.tie
                  ? 'تعادل'
                  : (r.ok ? 'نجح ${n[by]} (المشتري)' : 'خسر ${n[by]} (المشتري)'),
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: r.ok ? Colors.green : (r.tie ? null : cs.error)),
            ),
            _line('النتيجة النهائية — ${n[0]}: ${r.fin[0]} ، ${n[1]}: ${r.fin[1]}'),
            OutlinedButton(
                onPressed: () => widget.onRegister(r.fin[0], r.fin[1]),
                child: const Text('سجّلها في النتيجة')),
          ],
        ],
      ),
    );
  }
}
