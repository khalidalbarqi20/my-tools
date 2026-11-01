import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'html_host.dart';
import 'html_model.dart';
import 'html_runner_page.dart';

const _blank = '''<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>صفحتي</title>
<style>
  body { font-family: sans-serif; margin: 0; padding: 24px; }
</style>
</head>
<body>
  <h1>مرحبًا</h1>
  <script>
  </script>
</body>
</html>
''';

const _todo = '''<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>قائمة مهام</title>
<style>
  body { font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 20px; }
  form { display: flex; gap: 8px; }
  input { flex: 1; padding: 10px; font-size: 16px; }
  button { padding: 10px 14px; font-size: 16px; }
  li { padding: 10px 0; border-bottom: 1px solid #8884; display: flex; justify-content: space-between; }
  .done span { text-decoration: line-through; opacity: .5; }
</style>
</head>
<body>
  <h2>قائمة المهام</h2>
  <form id="f"><input id="t" placeholder="مهمة جديدة"><button>إضافة</button></form>
  <ul id="l"></ul>
<script>
  let items = [];
  try { items = JSON.parse(localStorage.getItem('todo') || '[]'); } catch (e) {}
  const save = () => { try { localStorage.setItem('todo', JSON.stringify(items)); } catch (e) {} };
  function draw() {
    const l = document.getElementById('l');
    l.innerHTML = '';
    items.forEach((it, i) => {
      const li = document.createElement('li');
      if (it.done) li.className = 'done';
      const s = document.createElement('span');
      s.textContent = it.text;
      s.onclick = () => { it.done = !it.done; save(); draw(); };
      const d = document.createElement('button');
      d.textContent = '✕';
      d.onclick = () => { items.splice(i, 1); save(); draw(); };
      li.append(s, d);
      l.append(li);
    });
  }
  document.getElementById('f').onsubmit = (e) => {
    e.preventDefault();
    const t = document.getElementById('t');
    if (!t.value.trim()) return;
    items.push({ text: t.value.trim(), done: false });
    t.value = '';
    save(); draw();
  };
  draw();
</script>
</body>
</html>
''';

const _counter = '''<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>عدّاد</title>
<style>
  body { font-family: sans-serif; text-align: center; padding-top: 60px; }
  #n { font-size: 96px; font-weight: 300; }
  button { font-size: 28px; width: 80px; height: 80px; border-radius: 50%; margin: 8px; }
</style>
</head>
<body>
  <div id="n">0</div>
  <button onclick="add(-1)">−</button>
  <button onclick="add(1)">+</button>
  <p><a href="#" onclick="reset();return false">تصفير</a></p>
<script>
  let n = 0;
  try { n = parseInt(localStorage.getItem('count') || '0', 10) || 0; } catch (e) {}
  const show = () => { document.getElementById('n').textContent = n; try { localStorage.setItem('count', n); } catch (e) {} };
  const add = (d) => { n += d; show(); };
  const reset = () => { n = 0; show(); };
  show();
</script>
</body>
</html>
''';

/// محرر HTML بسيط: اكتب الكود أو ابدأ من قالب، ثم «تشغيل» لحفظه ومعاينته.
class HtmlEditorPage extends StatefulWidget {
  final HtmlApp? app;
  const HtmlEditorPage({super.key, this.app});
  @override
  State<HtmlEditorPage> createState() => _HtmlEditorPageState();
}

class _HtmlEditorPageState extends State<HtmlEditorPage> {
  final _name = TextEditingController(text: 'صفحتي');
  final _code = TextEditingController(text: _blank);
  String? _id;
  bool _busy = false;
  String? _e;

  @override
  void initState() {
    super.initState();
    final a = widget.app;
    if (a != null) {
      _id = a.id;
      _name.text = a.name;
      _load(a);
    }
  }

  Future<void> _load(HtmlApp a) async {
    final b = await hostReadBytes(a.id);
    if (b != null && mounted) setState(() => _code.text = utf8.decode(b, allowMalformed: true));
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (!hostSupported) {
      setState(() => _e = 'غير مدعوم على هذا الجهاز.');
      return;
    }
    if (_code.text.trim().isEmpty) {
      setState(() => _e = 'اكتب الكود أولًا.');
      return;
    }
    setState(() {
      _busy = true;
      _e = null;
    });
    try {
      final name = _name.text.trim().isEmpty ? 'صفحتي' : _name.text.trim();
      final a = await hostAddBytes(name, Uint8List.fromList(utf8.encode(_code.text)), zip: false);
      if (a == null) throw const FormatException('تعذر الحفظ');
      final old = _id;
      _id = a.id;
      if (old != null) await hostDelete(old);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => HtmlViewerPage(app: a)));
    } catch (e) {
      if (mounted) setState(() => _e = e is FormatException ? e.message : 'تعذر الحفظ');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _template(String code, String name) {
    setState(() {
      _code.text = code;
      if (_id == null) _name.text = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('محرر HTML')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الصفحة')),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(label: const Text('صفحة فارغة'), onPressed: () => _template(_blank, 'صفحتي')),
          ActionChip(label: const Text('قائمة مهام'), onPressed: () => _template(_todo, 'قائمة مهام')),
          ActionChip(label: const Text('عدّاد'), onPressed: () => _template(_counter, 'عدّاد')),
        ]),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _code,
            minLines: 16,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(alignLabelWithHint: true, labelText: 'الكود'),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: _busy ? null : _run,
            icon: const Icon(Icons.play_arrow),
            label: const Text('تشغيل ومعاينة')),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (_e != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_e!, style: TextStyle(color: t.colorScheme.error))),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('«تشغيل» يحفظ الصفحة في قائمة «تشغيل صفحة HTML» ويفتحها. ارجع هنا وعدّل، وكل تشغيل يحدّث نفس الصفحة.',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}
