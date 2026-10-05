import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/display_card.dart';
import 'random_logic.dart';

Widget _animated(Object key, Widget child) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );

void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('تم النسخ')));
}

// ───────────────────────── رقم عشوائي ─────────────────────────
class RandomNumberPage extends StatefulWidget {
  const RandomNumberPage({super.key});
  @override
  State<RandomNumberPage> createState() => _RandomNumberPageState();
}

class _RandomNumberPageState extends State<RandomNumberPage> {
  final _min = TextEditingController(text: '1');
  final _max = TextEditingController(text: '100');
  final _count = TextEditingController(text: '1');
  bool _unique = false;
  List<int> _res = [];
  String? _err;
  int _n = 0;

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _count.dispose();
    super.dispose();
  }

  void _gen() {
    final a = parseWhole(_min.text),
        b = parseWhole(_max.text),
        c = parseWhole(_count.text);
    if (a == null || b == null || c == null) {
      setState(() {
        _err = 'أدخل أرقامًا صحيحة (بدون كسور)';
        _res = [];
      });
      return;
    }
    try {
      final r = randomNumbers(a, b, c, unique: _unique);
      setState(() {
        _res = r;
        _err = null;
        _n++;
      });
    } on FormatException catch (e) {
      setState(() {
        _err = e.message;
        _res = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final text = _res.join('، ');
    return Scaffold(
      appBar: AppBar(title: const Text('رقم عشوائي')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _min,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: 'من'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _max,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: 'إلى'),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _count,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'كم رقمًا؟'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('بدون تكرار'),
          value: _unique,
          onChanged: (v) => setState(() => _unique = v),
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _gen, child: const Text('توليد')),
        const SizedBox(height: 20),
        if (_err != null)
          Text(_err!, style: TextStyle(color: t.colorScheme.error)),
        if (_res.isNotEmpty) ...[
          DisplayCard(
            child: _animated(
              _n,
              Center(
                child: SelectableText(
                  text,
                  textAlign: TextAlign.center,
                  style: (_res.length == 1
                          ? t.textTheme.displayMedium
                          : t.textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton(
                onPressed: () => _copy(context, text),
                child: const Text('نسخ النتيجة')),
          ),
        ],
      ]),
    );
  }
}

// ───────────────────────── النرد ─────────────────────────
class DicePage extends StatefulWidget {
  const DicePage({super.key});
  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> {
  int _sides = 6, _count = 1, _n = 0;
  List<int> _res = [];

  void _roll() => setState(() {
        _res = rollDice(_sides, _count);
        _n++;
      });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final total = _res.fold<int>(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: const Text('رمي النرد')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('عدد الأوجه', style: t.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final s in const [4, 6, 8, 10, 12, 20, 100])
            ChoiceChip(
              label: Text('$s'),
              selected: _sides == s,
              onSelected: (_) => setState(() {
                _sides = s;
                _res = [];
              }),
            ),
        ]),
        const SizedBox(height: 16),
        Text('عدد النرد', style: t.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final c in const [1, 2, 3, 4, 5, 6])
            ChoiceChip(
              label: Text('$c'),
              selected: _count == c,
              onSelected: (_) => setState(() {
                _count = c;
                _res = [];
              }),
            ),
        ]),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _roll,
          icon: const Icon(Icons.casino_outlined),
          label: const Text('ارمِ'),
        ),
        const SizedBox(height: 20),
        if (_res.isNotEmpty)
          DisplayCard(
            child: _animated(
              _n,
              Column(children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final v in _res)
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('$v',
                            style: t.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimaryContainer)),
                      ),
                  ],
                ),
                if (_res.length > 1) ...[
                  const SizedBox(height: 12),
                  Text('المجموع: $total', style: t.textTheme.titleMedium),
                ],
              ]),
            ),
          ),
      ]),
    );
  }
}

// ───────────────────────── العملة ─────────────────────────
class CoinPage extends StatefulWidget {
  const CoinPage({super.key});
  @override
  State<CoinPage> createState() => _CoinPageState();
}

class _CoinPageState extends State<CoinPage> {
  bool? _heads;
  int _h = 0, _tl = 0, _n = 0;

  void _flip() => setState(() {
        final h = coinFlip();
        _heads = h;
        if (h) {
          _h++;
        } else {
          _tl++;
        }
        _n++;
      });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('رمي العملة')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        DisplayCard(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          child: _animated(
            _n,
            Column(children: [
              Icon(Icons.monetization_on_outlined,
                  size: 72, color: cs.primary),
              const SizedBox(height: 12),
              Text(
                _heads == null ? 'اضغط للرمي' : (_heads! ? 'صورة' : 'كتابة'),
                style: t.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _flip, child: const Text('ارمِ العملة')),
        if (_n > 0) ...[
          const SizedBox(height: 16),
          Text('صورة: $_h   •   كتابة: $_tl',
              textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
        ],
      ]),
    );
  }
}

// ───────────────────────── اختيار عشوائي ─────────────────────────
class PickerPage extends StatefulWidget {
  const PickerPage({super.key});
  @override
  State<PickerPage> createState() => _PickerPageState();
}

class _PickerPageState extends State<PickerPage> {
  final _c = TextEditingController();
  String? _picked;
  List<String> _order = [];
  String? _err;
  int _n = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _pick() {
    try {
      final p = pickRandom(parseItems(_c.text));
      setState(() {
        _picked = p;
        _order = [];
        _err = null;
        _n++;
      });
    } on FormatException catch (e) {
      setState(() {
        _err = e.message;
        _picked = null;
      });
    }
  }

  void _shuffle() {
    final items = parseItems(_c.text);
    if (items.isEmpty) {
      setState(() {
        _err = 'أضف خيارًا واحدًا على الأقل';
        _order = [];
      });
      return;
    }
    setState(() {
      _order = shuffled(items);
      _picked = null;
      _err = null;
      _n++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار عشوائي')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(
          controller: _c,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'الخيارات',
            hintText: 'اكتب كل خيار في سطر، أو افصل بينها بفاصلة',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: FilledButton(onPressed: _pick, child: const Text('اختر واحدًا'))),
          const SizedBox(width: 12),
          Expanded(
              child: OutlinedButton(
                  onPressed: _shuffle, child: const Text('ترتيب عشوائي'))),
        ]),
        const SizedBox(height: 20),
        if (_err != null)
          Text(_err!, style: TextStyle(color: t.colorScheme.error)),
        if (_picked != null)
          DisplayCard(
            child: _animated(
              _n,
              Center(
                child: SelectableText(_picked!,
                    textAlign: TextAlign.center,
                    style: t.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        if (_order.isNotEmpty)
          DisplayCard(
            child: _animated(
              _n,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var i = 0; i < _order.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${i + 1}.  ${_order[i]}',
                        style: t.textTheme.titleMedium),
                  ),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ───────────────────────── نعم / لا ─────────────────────────
class YesNoPage extends StatefulWidget {
  const YesNoPage({super.key});
  @override
  State<YesNoPage> createState() => _YesNoPageState();
}

class _YesNoPageState extends State<YesNoPage> {
  bool? _yes;
  int _n = 0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('نعم / لا')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        DisplayCard(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
          child: _animated(
            _n,
            Center(
              child: Text(
                _yes == null ? 'فكّر في سؤالك ثم اضغط' : (_yes! ? 'نعم' : 'لا'),
                textAlign: TextAlign.center,
                style: (_yes == null
                        ? t.textTheme.titleLarge
                        : t.textTheme.displayMedium)
                    ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _yes == null ? null : cs.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() {
            _yes = coinFlip();
            _n++;
          }),
          child: const Text('اسأل'),
        ),
      ]),
    );
  }
}

// ───────────────────────── العدّاد ─────────────────────────
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  static const _key = 'counter_v1';
  int _v = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getInt(_key) ?? 0;
      if (mounted) setState(() => _v = v);
    } catch (_) {}
  }

  Future<void> _set(int v) async {
    setState(() => _v = v);
    HapticFeedback.selectionClick();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_key, v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('العدّاد')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        DisplayCard(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Center(
            child: Text('$_v',
                style: t.textTheme.displayLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _set(_v - 1),
              child: const Icon(Icons.remove),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () => _set(_v + 1),
              child: const Icon(Icons.add),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _v == 0 ? null : () => _set(0),
          child: const Text('تصفير'),
        ),
      ]),
    );
  }
}
