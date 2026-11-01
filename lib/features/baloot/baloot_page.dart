import 'dart:convert';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../settings/color_picker.dart';
import 'baloot_logic.dart';

// حاسبة البلوت — نقل مطابق لصفحة الـ HTML الأصلية (نفس التخطيط والإعدادات والألوان والصوت).

const _kHist = 'baloot_hist';
const _kSet = 'baloot_set';
const _kOldNames = 'baloot_names';
const _win = 152;

int _int(String s) => int.tryParse(s.trim()) ?? 0;

class _Pal {
  final Color bg, card, fg, ok;
  const _Pal(this.bg, this.card, this.fg, this.ok);
  static const def =
      _Pal(Color(0xFF0B1530), Color(0xFF15234D), Color(0xFFFFFFFF), Color(0xFF4ADE80));
  Color get line => fg.withAlpha(46);
  Color get mut => fg.withAlpha(153);
  Color get bad => const Color(0xFFF87171);
  _Pal set(String k, Color c) => _Pal(k == 'bg' ? c : bg, k == 'card' ? c : card,
      k == 'fg' ? c : fg, k == 'ok' ? c : ok);
}

const _shadow = [
  BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(0, 6)),
  BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
];

class BalootPage extends StatefulWidget {
  const BalootPage({super.key});
  @override
  State<BalootPage> createState() => _BalootPageState();
}

class _BalootPageState extends State<BalootPage> {
  SharedPreferences? _p;
  List<List<int>> _h = [];
  List<String> _n = ['لنا', 'لهم'];
  _Pal _pal = _Pal.def;
  bool _snd = true, _wake = true, _showSet = false;
  String _sm = 'rand';
  List<String> _sounds = [];
  final _ia = TextEditingController();
  final _ib = TextEditingController();
  final _fa = FocusNode();
  final _fb = FocusNode();
  final _n0 = TextEditingController();
  final _n1 = TextEditingController();
  final _sc = ScrollController();
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _n0.text = _n[0];
    _n1.text = _n[1];
    _load();
    _loadSounds();
    _applyWake();
  }

  @override
  void dispose() {
    _ia.dispose();
    _ib.dispose();
    _fa.dispose();
    _fb.dispose();
    _n0.dispose();
    _n1.dispose();
    _sc.dispose();
    _player.dispose();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final h = p.getStringList(_kHist) ?? [];
      var names = p.getStringList(_kOldNames);
      var pal = _Pal.def;
      var snd = true, wake = true;
      var sm = 'rand';
      final raw = p.getString(_kSet);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final n = m['n'];
        if (n is List && n.length == 2) names = [for (final x in n) '$x'];
        final c = m['c'];
        if (c is Map) {
          Color col(String k, Color d) => c[k] is int ? Color(c[k] as int) : d;
          pal = _Pal(col('bg', pal.bg), col('card', pal.card), col('fg', pal.fg),
              col('ok', pal.ok));
        }
        if (m['snd'] is bool) snd = m['snd'] as bool;
        if (m['wake'] is bool) wake = m['wake'] as bool;
        if (m['sm'] is String) sm = m['sm'] as String;
      }
      if (!mounted) return;
      setState(() {
        _p = p;
        _h = [
          for (final s in h)
            [for (final x in s.split(',')) int.tryParse(x) ?? 0]
        ].where((r) => r.length == 2).toList();
        if (names != null && names.length == 2) _n = names;
        _pal = pal;
        _snd = snd;
        _wake = wake;
        _sm = sm;
      });
      _n0.text = _n[0];
      _n1.text = _n[1];
      _applyWake();
    } catch (_) {}
  }

  void _saveHist() {
    _p?.setStringList(_kHist, [for (final r in _h) '${r[0]},${r[1]}']);
  }

  void _saveSet() {
    _p?.setString(
        _kSet,
        jsonEncode({
          'n': _n,
          'c': {
            'bg': _pal.bg.toARGB32(),
            'card': _pal.card.toARGB32(),
            'fg': _pal.fg.toARGB32(),
            'ok': _pal.ok.toARGB32(),
          },
          'snd': _snd,
          'sm': _sm,
          'wake': _wake,
        }));
  }

  int _num(String a) =>
      int.tryParse(RegExp(r'sound(\d+)').firstMatch(a)?.group(1) ?? '') ?? 0;

  Future<void> _loadSounds() async {
    try {
      final man = await AssetManifest.loadFromAssetBundle(rootBundle);
      final l = man
          .listAssets()
          .where((a) => a.startsWith('assets/baloot/sound'))
          .toList()
        ..sort((a, b) => _num(a).compareTo(_num(b)));
      if (mounted) setState(() => _sounds = l);
    } catch (_) {}
  }

  Future<void> _playWin({bool test = false}) async {
    if (!_snd && !test) return;
    try {
      if (_sounds.isNotEmpty) {
        var path = _sounds[math.Random().nextInt(_sounds.length)];
        if (_sm != 'rand') {
          for (final s in _sounds) {
            if ('${_num(s)}' == _sm) path = s;
          }
        }
        await _player.stop();
        await _player.play(AssetSource(path.replaceFirst('assets/', '')));
      }
      if ((await Vibration.hasVibrator()) == true) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
    } catch (_) {}
  }

  void _applyWake() {
    try {
      if (_wake) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    } catch (_) {}
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
    _saveHist();
    _checkWin();
  }

  void _checkWin() {
    final t = _tot;
    if ((t[0] >= _win || t[1] >= _win) && t[0] != t[1]) {
      final loser = t[0] > t[1] ? _n[1] : _n[0];
      _playWin();
      showDialog<void>(
        context: context,
        builder: (c) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
            decoration: BoxDecoration(
              color: _pal.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _pal.ok, width: 2),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('قامت على $loser',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _pal.fg,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none)),
              const SizedBox(height: 20),
              Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                _pill('صكة جديدة', () {
                  Navigator.pop(c);
                  _reset();
                }),
                _pill('إغلاق', () => Navigator.pop(c)),
              ]),
            ]),
          ),
        ),
      );
    }
  }

  Widget _pill(String t, VoidCallback onTap) => Material(
        color: _pal.fg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(t,
                style: TextStyle(
                    color: _pal.bg, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      );

  void _reset() {
    setState(() => _h = []);
    _saveHist();
  }

  Future<void> _newGame() async {
    if (_h.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تبدأ لعبة جديدة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('نعم')),
        ],
      ),
    );
    if (ok == true) _reset();
  }

  void _undo() {
    if (_h.isEmpty) return;
    setState(() => _h.removeLast());
    _saveHist();
  }

  void _setName(int i, String v) {
    setState(() => _n[i] = v.trim().isEmpty ? (i == 1 ? 'لهم' : 'لنا') : v.trim());
    _saveSet();
  }

  Future<void> _pickCol(String k, String title) async {
    final cur = {'bg': _pal.bg, 'card': _pal.card, 'fg': _pal.fg, 'ok': _pal.ok}[k]!;
    final c = await pickColor(context, initial: cur, title: title);
    if (c != null) {
      setState(() => _pal = _pal.set(k, c));
      _saveSet();
    }
  }

  // ───────── عناصر الواجهة ─────────

  InputDecoration _fieldDeco({String? label, String? hint}) {
    final b = OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _pal.line));
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: _pal.bg,
      hintText: hint,
      hintStyle: TextStyle(color: _pal.mut),
      border: b,
      enabledBorder: b,
      focusedBorder: b.copyWith(borderSide: BorderSide(color: _pal.ok, width: 2)),
      contentPadding: const EdgeInsets.all(12),
    );
  }

  Widget _label(String s) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(s, style: TextStyle(fontSize: 14, color: _pal.mut)),
        ),
      );

  Widget _btn(String t, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _pal.line)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(t,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _pal.fg, fontSize: 16)),
              ),
            ),
          ),
        ),
      );

  Widget _colorRow(String k, String title, Color c) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: InkWell(
          onTap: () => _pickCol(k, title),
          child: Row(children: [
            Container(
              width: 46,
              height: 36,
              decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _pal.line)),
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: _pal.fg)),
          ]),
        ),
      );

  Widget _check(String t, bool v, ValueChanged<bool> on) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
          onTap: () => on(!v),
          child: Row(children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: v,
                activeColor: _pal.ok,
                checkColor: _pal.bg,
                side: BorderSide(color: _pal.mut, width: 2),
                onChanged: (x) => on(x ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: TextStyle(color: _pal.fg, fontSize: 16))),
          ]),
        ),
      );

  Widget _settings() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'rand', child: Text('عشوائي من الكل')),
      for (final s in _sounds)
        DropdownMenuItem(value: '${_num(s)}', child: Text('صوت ${_num(s)}')),
    ];
    final cur = items.any((e) => e.value == _sm) ? _sm : 'rand';
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _pal.card, borderRadius: BorderRadius.circular(16), boxShadow: _shadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('الإعدادات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _pal.fg)),
        _label('اسم الفريق الأول'),
        TextField(
            controller: _n0,
            textAlign: TextAlign.center,
            style: TextStyle(color: _pal.fg, fontSize: 17),
            decoration: _fieldDeco(),
            onChanged: (v) => _setName(0, v)),
        _label('اسم الفريق الثاني'),
        TextField(
            controller: _n1,
            textAlign: TextAlign.center,
            style: TextStyle(color: _pal.fg, fontSize: 17),
            decoration: _fieldDeco(),
            onChanged: (v) => _setName(1, v)),
        _label('الألوان'),
        _colorRow('bg', 'الخلفية', _pal.bg),
        _colorRow('card', 'البطاقات', _pal.card),
        _colorRow('fg', 'النص', _pal.fg),
        _colorRow('ok', 'لون التحديد', _pal.ok),
        _btn('إعادة الألوان الافتراضية', () {
          setState(() => _pal = _Pal.def);
          _saveSet();
        }),
        _check('تشغيل صوت عند الوصول إلى ١٥٢', _snd, (v) {
          setState(() => _snd = v);
          _saveSet();
        }),
        _label('صوت الفوز'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              color: _pal.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _pal.line)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: cur,
              dropdownColor: _pal.card,
              style: TextStyle(color: _pal.fg, fontSize: 17),
              items: items,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _sm = v);
                _saveSet();
              },
            ),
          ),
        ),
        if (_sounds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('ضع ملفات الصوت باسم sound1.mp3 و sound2.mp3 … في assets/baloot',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _pal.mut)),
          ),
        _btn('▶ تجربة الصوت', () => _playWin(test: true)),
        _check('إبقاء الشاشة تعمل أثناء استخدام التطبيق', _wake, (v) {
          setState(() => _wake = v);
          _applyWake();
          _saveSet();
        }),
      ]),
    );
  }

  Widget _circleInput(TextEditingController c, FocusNode fn, String hint,
      TextEditingController o, FocusNode ofn) {
    const none = InputBorder.none;
    return SizedBox(
      width: 104,
      height: 104,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pal.card,
          border: Border.all(color: _pal.line, width: 6),
          boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 10)],
        ),
        child: Center(
          child: TextField(
            controller: c,
            focusNode: fn,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(fontSize: 30, color: _pal.fg),
            onChanged: (v) {
              if (v.length >= 2 && o.text.isEmpty) ofn.requestFocus();
            },
            decoration: InputDecoration(
              filled: false,
              isCollapsed: true,
              border: none,
              enabledBorder: none,
              focusedBorder: none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              hintText: hint,
              hintStyle: TextStyle(fontSize: 18, color: _pal.mut),
            ),
          ),
        ),
      ),
    );
  }

  Widget _goButton() => Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _pal.fg, boxShadow: _shadow),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _addRound(_int(_ia.text), _int(_ib.text)),
            child: Center(
              child: Text('احسب',
                  style: TextStyle(
                      color: _pal.bg, fontSize: 22, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );

  Widget _link(String t, Color c, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c, width: 3))),
          child: Text(t, style: TextStyle(color: c, fontSize: 18)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = _pal;
    final base = Theme.of(context);
    final b = ThemeData.estimateBrightnessForColor(p.bg) == Brightness.dark
        ? Brightness.dark
        : Brightness.light;
    final theme = base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: p.ok, brightness: b)
          .copyWith(surface: p.bg, onSurface: p.fg, primary: p.ok),
      scaffoldBackgroundColor: p.bg,
      appBarTheme: AppBarTheme(
          backgroundColor: p.bg,
          foregroundColor: p.fg,
          elevation: 0,
          scrolledUnderElevation: 0),
    );
    final tot = _tot;
    final a = tot[0], bb = tot[1];
    var banner = '';
    var bannerBad = false;
    if (a >= _win || bb >= _win) {
      if (a == bb) {
        banner = 'تعادل ($a) — لازم صكة زيادة';
        bannerBad = true;
      } else {
        banner = 'الفوز ${a > bb ? _n[0] : _n[1]} 🎉';
      }
    }
    Widget score(String name, int v) => Expanded(
          child: Column(children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: p.fg,
                    shadows: const [Shadow(color: Color(0x80000000), blurRadius: 10)])),
            Text('$v',
                style: TextStyle(
                    fontSize: 68,
                    fontWeight: FontWeight.w300,
                    color: p.fg,
                    shadows: const [Shadow(color: Color(0x80000000), blurRadius: 10)])),
          ]),
        );
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: const Text('حاسبة البلوت')),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                controller: _sc,
                padding: const EdgeInsets.all(16),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      tooltip: 'الإعدادات',
                      icon: const Text('⚙️', style: TextStyle(fontSize: 24)),
                      onPressed: () => setState(() => _showSet = !_showSet),
                    ),
                  ),
                  if (_showSet) _settings(),
                  Row(children: [score(_n[0], a), score(_n[1], bb)]),
                  Container(
                    constraints: const BoxConstraints(minHeight: 28),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    child: Text(banner,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: bannerBad ? p.bad : p.ok)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleInput(_ia, _fa, _n[0], _ib, _fb),
                      _goButton(),
                      _circleInput(_ib, _fb, _n[1], _ia, _fa),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _link('صكة جديدة', p.ok, _newGame),
                      _link('تراجع', p.bad, _undo),
                    ]),
                  ),
                  for (final r in _h.reversed)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: p.line))),
                      child: Row(children: [
                        Expanded(
                            child: Text('${r[0]}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 22, color: p.fg))),
                        Expanded(
                            child: Text('${r[1]}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 22, color: p.fg))),
                      ]),
                    ),
                  _CalcCard(
                      kind: BalootKind.sun,
                      pal: p,
                      names: _n,
                      onRegister: _register),
                  _CalcCard(
                      kind: BalootKind.hakam,
                      pal: p,
                      names: _n,
                      onRegister: _register),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _register(int a, int b) {
    _addRound(a, b);
    if (_sc.hasClients) {
      _sc.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
}

class _CalcCard extends StatefulWidget {
  final BalootKind kind;
  final _Pal pal;
  final List<String> names;
  final void Function(int, int) onRegister;
  const _CalcCard(
      {required this.kind,
      required this.pal,
      required this.names,
      required this.onRegister});
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

  _Pal get _p => widget.pal;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(children: [
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _p.mut)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                  color: _p.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _p.line)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: v,
                  icon: const SizedBox.shrink(),
                  dropdownColor: _p.card,
                  style: TextStyle(color: _p.fg, fontSize: 17),
                  items: [
                    for (var i = 0; i <= max; i++)
                      DropdownMenuItem(value: i, child: Center(child: Text('$i')))
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
              ),
            ),
          ]),
        ),
      );

  Widget _label(String s) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(s, style: TextStyle(fontSize: 14, color: _p.mut)),
        ),
      );

  Widget _projects(int team) {
    final names = balootProjectNames(widget.kind);
    final hasBal = balootHasBalot(widget.kind);
    return Column(children: [
      _label('مشاريع ${widget.names[team]}'),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var j = 0; j < names.length; j++)
          _pick(names[j], _proj[team][j], 4, (x) => _proj[team][j] = x),
        if (hasBal) _pick('بلوت', _bal[team], 1, (x) => _bal[team] = x),
      ]),
    ]);
  }

  Widget _numField(int i, String label) => Column(children: [
        _label(label),
        TextField(
          controller: _f[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: _p.fg, fontSize: 17),
          onChanged: (_) => _typed(i),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _p.bg,
            hintText: '0',
            hintStyle: TextStyle(color: _p.mut),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _p.line)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _p.line)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _p.ok, width: 2)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ]);

  Widget _buyBtn(int i) {
    final sel = _buy == i;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: i == 0 ? 5 : 0, right: i == 1 ? 5 : 0),
        child: Container(
          decoration: BoxDecoration(
            color: sel ? _p.ok : _p.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? _p.ok : _p.line, width: 2),
            boxShadow: sel
                ? [BoxShadow(color: _p.ok, blurRadius: 14)]
                : const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _setBuyer(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(widget.names[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        color: sel ? const Color(0xFF04210A) : _p.fg,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pointsLine(String who, int pts, int cards) {
    final extra = pts - cards;
    final tail = extra != 0 ? ' + $extra مشاريع' : '';
    return _rich('نقاط $who: ', '$pts', ' ($cards أوراق$tail)');
  }

  Widget _rich(String a, String bold, String c) => Text.rich(
        TextSpan(style: TextStyle(color: _p.fg, height: 1.8), children: [
          TextSpan(text: a),
          TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: c),
        ]),
      );

  Widget _line(String s) => Text(s, style: TextStyle(color: _p.fg, height: 1.8));

  @override
  Widget build(BuildContext context) {
    final k = widget.kind;
    final n = widget.names;
    final by = _buy;
    final pi = balootGameTotal(k, _team(0), _team(1));
    final total = balootTotal(k);
    Widget? sum;
    final f0 = int.tryParse(_f[0].text.trim());
    if (_anchor >= 0 && f0 != null) {
      final ev = balootEval(k, by, f0, _team(0), _team(1));
      if (!ev.outOfRange) {
        sum = Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Center(
            child: Text.rich(
              TextSpan(style: TextStyle(color: _p.mut, fontSize: 16), children: [
                TextSpan(text: 'المجموع مع المشاريع — ${n[by]}: '),
                TextSpan(
                    text: '${ev.points[by]}',
                    style: TextStyle(color: _p.fg, fontWeight: FontWeight.w700)),
                TextSpan(text: ' | ${n[1 - by]}: '),
                TextSpan(
                    text: '${ev.points[1 - by]}',
                    style: TextStyle(color: _p.fg, fontWeight: FontWeight.w700)),
              ]),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }
    final r = _res;
    return Container(
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
          BoxShadow(color: Color(0x4D000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: _p.fg,
          collapsedIconColor: _p.fg,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(balootTitle(k),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _p.fg)),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [
            _label('المشتري'),
            Row(children: [_buyBtn(0), _buyBtn(1)]),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text.rich(
                  TextSpan(style: TextStyle(color: _p.mut, fontSize: 16), children: [
                    const TextSpan(text: 'إجمالي اللعب: '),
                    TextSpan(
                        text: '$pi',
                        style: TextStyle(
                            color: _p.fg, fontSize: 24, fontWeight: FontWeight.w700)),
                    const TextSpan(text: ' نقطة'),
                  ]),
                ),
              ),
            ),
            _numField(0, 'نقاط ${n[by]} (المشتري) من الأوراق (من $total)'),
            _numField(1, 'نقاط ${n[1 - by]} (الخصم) — تظهر تلقائياً'),
            if (sum != null) sum,
            _projects(0),
            _projects(1),
            const SizedBox(height: 12),
            Material(
              color: _p.fg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _calc,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('احسب',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _p.bg, fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                ),
              ),
            ),
            if (_msg != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_msg!, style: TextStyle(color: _p.bad)),
              ),
            if (r != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _rich('إجمالي اللعب: ', '${r.total}', ' نقطة'),
                  _pointsLine('${n[by]} (المشتري)', r.points[by], r.cards[by]),
                  _pointsLine('${n[1 - by]} (الخصم)', r.points[1 - by], r.cards[1 - by]),
                  _line('الأعداد — ${n[0]}: ${r.counts[0]} | ${n[1]}: ${r.counts[1]}'),
                  Text(
                    r.tie
                        ? 'تعادل'
                        : (r.ok ? 'نجح ${n[by]} (المشتري)' : 'خسر ${n[by]} (المشتري)'),
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: r.ok ? _p.ok : (r.tie ? _p.fg : _p.bad)),
                  ),
                  _line('النتيجة النهائية — ${n[0]}: ${r.fin[0]} ، ${n[1]}: ${r.fin[1]}'),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _p.line)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => widget.onRegister(r.fin[0], r.fin[1]),
                      child: SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text('سجّلها في النتيجة',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _p.fg)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
