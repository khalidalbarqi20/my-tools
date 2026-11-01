import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../pdf/pdf_common.dart' show humanSize, pickPicked;
import 'dev_logic.dart';
import 'hash_logic.dart';

Widget _note(BuildContext c, String m) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(m,
          style: Theme.of(c)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(c).colorScheme.onSurfaceVariant)),
    );

Widget _err(BuildContext c, String m) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(m, style: TextStyle(color: Theme.of(c).colorScheme.error)));

Widget _mono(BuildContext c, String s) => Directionality(
      textDirection: TextDirection.ltr,
      child: SelectableText(s,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
    );

void _copy(BuildContext c, String s) {
  Clipboard.setData(ClipboardData(text: s));
  ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('تم النسخ')));
}

// ───────────── البصمة SHA ─────────────
class HashPage extends StatefulWidget {
  const HashPage({super.key});
  @override
  State<HashPage> createState() => _HashPageState();
}

class _HashPageState extends State<HashPage> {
  final _t = TextEditingController();
  final _cmp = TextEditingController();
  bool _s256 = true;
  String? _fileName, _fileHash;
  int _fileSize = 0;
  bool _busy = false;
  String? _e;

  @override
  void dispose() {
    _t.dispose();
    _cmp.dispose();
    super.dispose();
  }

  String _hash(List<int> d) => _s256 ? sha256Hex(d) : sha1Hex(d);

  Future<void> _pickFile() async {
    setState(() {
      _e = null;
      _busy = true;
    });
    try {
      final fs = await pickPicked(type: FileType.any);
      if (fs.isEmpty) return;
      final f = fs.first;
      if (f.bytes.length > 80 * 1024 * 1024) {
        throw const FormatException('الملف كبير (الحد 80 ميجابايت).');
      }
      await Future<void>.delayed(const Duration(milliseconds: 30));
      setState(() {
        _fileName = f.name;
        _fileSize = f.bytes.length;
        _fileHash = _hash(f.bytes);
      });
    } catch (e) {
      setState(() => _e = e is FormatException ? e.message : 'تعذر قراءة الملف');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txt = _t.text.isEmpty ? null : _hash(utf8.encode(_t.text));
    final target = (txt ?? _fileHash)?.toLowerCase();
    final want = _cmp.text.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(title: const Text('بصمة الملفات والنصوص (SHA)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('SHA-256')),
            ButtonSegment(value: false, label: Text('SHA-1')),
          ],
          selected: {_s256},
          onSelectionChanged: (s) => setState(() {
            _s256 = s.first;
            _fileHash = null;
            _fileName = null;
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _t,
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'اكتب نصًا'),
        ),
        if (txt != null) ...[
          const SizedBox(height: 8),
          _mono(context, txt),
          TextButton.icon(
              onPressed: () => _copy(context, txt),
              icon: const Icon(Icons.copy),
              label: const Text('نسخ')),
        ],
        const Divider(height: 32),
        OutlinedButton.icon(
            onPressed: _busy ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('اختر ملفًا')),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (_fileHash != null) ...[
          const SizedBox(height: 8),
          Text('$_fileName  •  ${humanSize(_fileSize)}'),
          const SizedBox(height: 4),
          _mono(context, _fileHash!),
          TextButton.icon(
              onPressed: () => _copy(context, _fileHash!),
              icon: const Icon(Icons.copy),
              label: const Text('نسخ')),
        ],
        if (_e != null) _err(context, _e!),
        const Divider(height: 32),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _cmp,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'قارن مع بصمة معروفة (اختياري)'),
          ),
        ),
        if (want.isNotEmpty && target != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(want == target ? 'متطابقة ✅' : 'غير متطابقة ❌',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: want == target ? Colors.green : Theme.of(context).colorScheme.error)),
          ),
        _note(context, 'كل شيء يُحسب داخل جهازك ولا يُرسل لأي خادم.'),
      ]),
    );
  }
}

// ───────────── فحص كلمة المرور ─────────────
class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _c = TextEditingController();
  bool _hide = true, _busy = false;
  String? _leak, _e;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_c.text.isEmpty) return;
    setState(() {
      _busy = true;
      _leak = null;
      _e = null;
    });
    try {
      final h = sha1Hex(utf8.encode(_c.text)).toUpperCase();
      final r = await http
          .get(Uri.parse('https://api.pwnedpasswords.com/range/${h.substring(0, 5)}'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) throw const FormatException('تعذر الفحص الآن');
      final n = hibpCount(r.body, h.substring(5));
      setState(() => _leak = n > 0
          ? 'ظهرت في تسريبات معروفة $n مرة ❌ لا تستخدمها'
          : 'ما ظهرت في التسريبات المعروفة ✅');
    } catch (e) {
      setState(() => _e = e is FormatException ? e.message : 'تعذر الاتصال بخدمة الفحص');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = passwordReport(_c.text);
    final cs = Theme.of(context).colorScheme;
    final colors = [cs.error, Colors.deepOrange, Colors.amber, Colors.lightGreen, Colors.green];
    return Scaffold(
      appBar: AppBar(title: const Text('فحص كلمة المرور')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _c,
            obscureText: _hide,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() => _leak = null),
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
        ),
        if (_c.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
              value: (r.level + 1) / 5,
              minHeight: 8,
              color: colors[r.level],
              borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 8),
          Text('${pwLevelAr[r.level]}  •  تقدير ${r.bits} بت',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final t in r.tips) Text('• $t'),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: _busy || _c.text.isEmpty ? null : _check,
            icon: const Icon(Icons.shield_outlined),
            label: const Text('هل تسربت في اختراق معروف؟')),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (_leak != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_leak!)),
        if (_e != null) _err(context, _e!),
        _note(context,
            'التقدير تقريبي. فحص التسريب يرسل أول ٥ خانات فقط من بصمة SHA-1 لخدمة Have I Been Pwned، وكلمة المرور نفسها لا تغادر جهازك.'),
      ]),
    );
  }
}

// ───────────── فك JWT ─────────────
class JwtPage extends StatefulWidget {
  const JwtPage({super.key});
  @override
  State<JwtPage> createState() => _JwtPageState();
}

class _JwtPageState extends State<JwtPage> {
  final _c = TextEditingController();
  JwtParts? _j;
  String? _e;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _run() {
    try {
      setState(() {
        _j = decodeJwt(_c.text);
        _e = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _j = null;
        _e = e.message;
      });
    }
  }

  String _pretty(Object o) => const JsonEncoder.withIndent('  ').convert(o);

  @override
  Widget build(BuildContext context) {
    final j = _j;
    String? expText;
    if (j?.exp != null) {
      final expired = j!.exp!.isBefore(DateTime.now().toUtc());
      expText = '${expired ? 'منتهي ❌' : 'ساري ✅'} — ${fmtDate(j.exp!)} UTC';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('فك JWT')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _c,
            minLines: 4,
            maxLines: 8,
            onChanged: (_) => _run(),
            decoration: const InputDecoration(labelText: 'الصق الرمز هنا'),
          ),
        ),
        if (_e != null && _c.text.trim().isNotEmpty) _err(context, _e!),
        if (j != null) ...[
          const SizedBox(height: 16),
          const Text('الترويسة (Header)', style: TextStyle(fontWeight: FontWeight.w700)),
          _mono(context, _pretty(j.header)),
          const SizedBox(height: 12),
          const Text('البيانات (Payload)', style: TextStyle(fontWeight: FontWeight.w700)),
          _mono(context, _pretty(j.payload)),
          if (expText != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text('الانتهاء: $expText')),
          if (j.iat != null) Text('الإصدار: ${fmtDate(j.iat!)} UTC'),
        ],
        _note(context, 'الفك محلي بالكامل. لا يتحقق من صحة التوقيع، فلا تعتمد عليه للتحقق الأمني.'),
      ]),
    );
  }
}

// ───────────── الطابع الزمني ─────────────
class TimestampPage extends StatefulWidget {
  const TimestampPage({super.key});
  @override
  State<TimestampPage> createState() => _TimestampPageState();
}

class _TimestampPageState extends State<TimestampPage> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context, initialDate: DateTime.now(), firstDate: DateTime(1970), lastDate: DateTime(2100));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() => _c.text = '${dt.millisecondsSinceEpoch ~/ 1000}');
  }

  @override
  Widget build(BuildContext context) {
    final d = parseTimestamp(_c.text);
    return Scaffold(
      appBar: AppBar(title: const Text('محول الطابع الزمني')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _c,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Unix timestamp (ثواني أو ملي ثانية)'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          OutlinedButton(
              onPressed: () => setState(() => _c.text = '${DateTime.now().millisecondsSinceEpoch ~/ 1000}'),
              child: const Text('الآن')),
          OutlinedButton(onPressed: _pickDate, child: const Text('من تاريخ ووقت')),
        ]),
        const SizedBox(height: 16),
        if (_c.text.trim().isNotEmpty && d == null) _err(context, 'رقم غير صالح'),
        if (d != null) ...[
          ListTile(title: const Text('UTC'), subtitle: _mono(context, fmtDate(d))),
          ListTile(title: const Text('توقيت جهازك'), subtitle: _mono(context, fmtDate(d.toLocal()))),
          ListTile(title: const Text('ISO 8601'), subtitle: _mono(context, d.toIso8601String())),
        ],
        _note(context, 'الأرقام من ١٣ خانة فأكثر تُعتبر ملي ثانية، وما دونها ثواني.'),
      ]),
    );
  }
}

// ───────────── مقارنة نصين ─────────────
class DiffPage extends StatefulWidget {
  const DiffPage({super.key});
  @override
  State<DiffPage> createState() => _DiffPageState();
}

class _DiffPageState extends State<DiffPage> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  List<DiffLine>? _d;
  String? _e;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _run() {
    try {
      final d = diffLines(const LineSplitter().convert(_a.text), const LineSplitter().convert(_b.text));
      setState(() {
        _d = d;
        _e = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _d = null;
        _e = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final adds = d?.where((x) => x.op == DiffOp.add).length ?? 0;
    final dels = d?.where((x) => x.op == DiffOp.del).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('مقارنة نصين')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
            controller: _a,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(labelText: 'النص الأول (الأصل)')),
        const SizedBox(height: 12),
        TextField(
            controller: _b,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(labelText: 'النص الثاني (الجديد)')),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: _run, icon: const Icon(Icons.compare_arrows), label: const Text('قارن')),
        if (_e != null) _err(context, _e!),
        if (d != null) ...[
          const SizedBox(height: 12),
          Text(adds == 0 && dels == 0 ? 'النصان متطابقان ✅' : 'أُضيف $adds سطر • حُذف $dels سطر',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final l in d)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: l.op == DiffOp.add
                  ? Colors.green.withAlpha(50)
                  : l.op == DiffOp.del
                      ? Colors.red.withAlpha(50)
                      : null,
              child: Text('${l.op == DiffOp.add ? '+ ' : l.op == DiffOp.del ? '− ' : '  '}${l.text}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            ),
        ],
      ]),
    );
  }
}
