import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'network_logic.dart';

const _cf = 'https://speed.cloudflare.com';

class _Rows extends StatelessWidget {
  final List<(String, String)> rows;
  const _Rows(this.rows);
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Column(children: [
        for (final r in rows)
          ListTile(
            dense: true,
            title: Text(r.$1,
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            subtitle: SelectableText(r.$2, style: t.textTheme.bodyLarge),
          ),
      ]),
    );
  }
}

Widget _err(BuildContext c, String m) =>
    Padding(padding: const EdgeInsets.only(top: 12), child: Text(m, style: TextStyle(color: Theme.of(c).colorScheme.error)));

Widget _note(BuildContext c, String m) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(m,
          style: Theme.of(c)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(c).colorScheme.onSurfaceVariant)),
    );

String _fail(Object e) => e is FormatException
    ? e.message
    : 'تعذر الاتصال. تأكد من الإنترنت وحاول مرة أخرى.';

// ───────────── عنوان IP والموقع ─────────────
class IpPage extends StatefulWidget {
  const IpPage({super.key});
  @override
  State<IpPage> createState() => _IpPageState();
}

class _IpPageState extends State<IpPage> {
  List<(String, String)>? _rows;
  String? _e;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _e = null;
    });
    try {
      final r = await http.get(Uri.parse('https://ipwho.is/')).timeout(const Duration(seconds: 12));
      final m = jsonDecode(r.body) as Map<String, dynamic>;
      if (m['success'] == false) throw const FormatException('تعذر تحديد العنوان.');
      final conn = (m['connection'] as Map?) ?? {};
      final tz = (m['timezone'] as Map?) ?? {};
      String v(Object? x) => (x == null || '$x'.isEmpty) ? '—' : '$x';
      setState(() => _rows = [
            ('عنوان IP', v(m['ip'])),
            ('النوع', v(m['type'])),
            ('الدولة', v(m['country'])),
            ('المنطقة', v(m['region'])),
            ('المدينة', v(m['city'])),
            ('مزوّد الخدمة', v(conn['isp'] ?? conn['org'])),
            ('المنطقة الزمنية', v(tz['id'])),
          ]);
    } catch (e) {
      setState(() => _e = _fail(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('عنوان IP وموقعي')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (_busy) const LinearProgressIndicator(),
          if (_rows != null) _Rows(_rows!),
          if (_e != null) _err(context, _e!),
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: _busy ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث')),
          _note(context, 'الموقع تقريبي ويعتمد على مزوّد الإنترنت، وقد يختلف عن موقعك الحقيقي. الطلب يُرسل لخدمة ipwho.is.'),
        ]),
      );
}

// ───────────── زمن الاستجابة والتذبذب ─────────────
class PingPage extends StatefulWidget {
  const PingPage({super.key});
  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage> {
  static const _count = 10;
  bool _busy = false;
  int _done = 0;
  double? _last;
  PingStats? _st;
  String? _e;

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _done = 0;
      _last = null;
      _st = null;
      _e = null;
    });
    final ok = <double>[];
    final c = http.Client();
    try {
      // طلب تسخين (يشمل الاتصال الآمن) لا يدخل في الحساب.
      try {
        await c.get(Uri.parse('$_cf/__down?bytes=0')).timeout(const Duration(seconds: 8));
      } catch (_) {}
      for (var i = 0; i < _count; i++) {
        final sw = Stopwatch()..start();
        try {
          final r = await c
              .get(Uri.parse('$_cf/__down?bytes=0&i=$i'))
              .timeout(const Duration(seconds: 5));
          sw.stop();
          if (r.statusCode == 200) {
            ok.add(sw.elapsedMicroseconds / 1000);
            _last = ok.last;
          }
        } catch (_) {}
        if (!mounted) return;
        setState(() => _done = i + 1);
      }
      if (ok.isEmpty) throw const FormatException('لا يوجد اتصال بالإنترنت.');
      setState(() => _st = pingStats(ok, _count));
    } catch (e) {
      if (mounted) setState(() => _e = _fail(e));
    } finally {
      c.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  String _f(double v) => v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final st = _st;
    return Scaffold(
      appBar: AppBar(title: const Text('زمن الاستجابة والتذبذب')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        FilledButton.icon(
            onPressed: _busy ? null : _run,
            icon: const Icon(Icons.network_ping),
            label: Text(_busy ? 'جاري القياس ($_done/$_count)' : 'ابدأ القياس')),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (_last != null && st == null)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text('آخر قياس: ${_f(_last!)} مللي ثانية')),
        if (st != null)
          _Rows([
            ('أقل زمن', '${_f(st.min)} مللي ثانية'),
            ('المتوسط', '${_f(st.avg)} مللي ثانية'),
            ('أعلى زمن', '${_f(st.max)} مللي ثانية'),
            ('التذبذب (Jitter)', '${_f(st.jitter)} مللي ثانية'),
            ('الفقد', '${st.lost} من ${st.sent} (${_f(st.lossPct)}%)'),
          ]),
        if (_e != null) _err(context, _e!),
        _note(context, 'القياس عبر طلبات HTTPS إلى خوادم Cloudflare، فهو أعلى قليلًا من ping الحقيقي. ping الحقيقي غير متاح في المتصفح.'),
      ]),
    );
  }
}

// ───────────── سرعة التحميل والرفع ─────────────
class SpeedPage extends StatefulWidget {
  const SpeedPage({super.key});
  @override
  State<SpeedPage> createState() => _SpeedPageState();
}

class _SpeedPageState extends State<SpeedPage> {
  bool _busy = false;
  String _stage = '';
  double? _down, _up;
  String? _e;

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _down = null;
      _up = null;
      _e = null;
      _stage = 'تحميل…';
    });
    final c = http.Client();
    try {
      final sw = Stopwatch()..start();
      final r = await c.get(Uri.parse('$_cf/__down?bytes=10000000')).timeout(const Duration(seconds: 40));
      sw.stop();
      if (r.statusCode != 200 || r.bodyBytes.isEmpty) {
        throw const FormatException('فشل اختبار التحميل.');
      }
      if (!mounted) return;
      setState(() {
        _down = mbps(r.bodyBytes.length, sw.elapsed);
        _stage = 'رفع…';
      });
      final data = Uint8List(3000000);
      final sw2 = Stopwatch()..start();
      final u = await c
          .post(Uri.parse('$_cf/__up'),
              headers: {'content-type': 'application/octet-stream'}, body: data)
          .timeout(const Duration(seconds: 40));
      sw2.stop();
      if (u.statusCode >= 400) throw const FormatException('فشل اختبار الرفع.');
      if (mounted) setState(() => _up = mbps(data.length, sw2.elapsed));
    } catch (e) {
      if (mounted) setState(() => _e = _fail(e));
    } finally {
      c.close();
      if (mounted) {
        setState(() {
          _busy = false;
          _stage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget big(String label, double? v) => Expanded(
          child: Column(children: [
            Text(label, style: t.textTheme.bodyMedium),
            Text(v == null ? '—' : v.toStringAsFixed(1),
                style: t.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w300)),
            Text('ميجابت/ث', style: t.textTheme.bodySmall),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('سرعة الإنترنت')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SizedBox(height: 8),
        Row(children: [big('التحميل', _down), big('الرفع', _up)]),
        const SizedBox(height: 20),
        FilledButton.icon(
            onPressed: _busy ? null : _run,
            icon: const Icon(Icons.speed),
            label: Text(_busy ? _stage : 'ابدأ الاختبار')),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (_e != null) _err(context, _e!),
        _note(context, 'الاختبار يحمّل نحو ١٠ ميجابايت ويرفع ٣ ميجابايت من خوادم Cloudflare، فاحذر إن كانت باقتك محدودة. النتيجة تقريبية.'),
      ]),
    );
  }
}

// ───────────── استعلام DNS ─────────────
class DnsPage extends StatefulWidget {
  const DnsPage({super.key});
  @override
  State<DnsPage> createState() => _DnsPageState();
}

class _DnsPageState extends State<DnsPage> {
  final _c = TextEditingController();
  String _type = 'A';
  bool _busy = false;
  List<(String, String)>? _rows;
  String? _status, _e;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final name = _c.text.trim().replaceAll(RegExp(r'^[a-z]+://', caseSensitive: false), '').split('/').first;
    if (name.isEmpty || !name.contains('.')) {
      setState(() => _e = 'اكتب اسم نطاق صحيح مثل example.com');
      return;
    }
    setState(() {
      _busy = true;
      _e = null;
      _rows = null;
      _status = null;
    });
    try {
      final u = Uri.https('cloudflare-dns.com', '/dns-query', {'name': name, 'type': _type});
      final r = await http.get(u, headers: {'accept': 'application/dns-json'}).timeout(const Duration(seconds: 12));
      final m = jsonDecode(r.body) as Map<String, dynamic>;
      final ans = (m['Answer'] as List?) ?? [];
      setState(() {
        _status = dnsStatusAr((m['Status'] as num?)?.toInt() ?? -1);
        _rows = [
          for (final a in ans)
            ('${dnsTypeName((a['type'] as num?)?.toInt() ?? 0)}  •  TTL ${a['TTL']}', '${a['data']}'),
        ];
      });
    } catch (e) {
      setState(() => _e = _fail(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('استعلام DNS')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _c,
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _run(),
              decoration: const InputDecoration(labelText: 'اسم النطاق', hintText: 'example.com'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final t in dnsTypes.keys)
              ChoiceChip(label: Text(t), selected: _type == t, onSelected: (_) => setState(() => _type = t)),
          ]),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: _busy ? null : _run,
              icon: const Icon(Icons.dns_outlined),
              label: const Text('استعلام')),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          if (_status != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text('الحالة: $_status')),
          if (_rows != null && _rows!.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('لا توجد سجلات من هذا النوع.')),
          if (_rows != null && _rows!.isNotEmpty) _Rows(_rows!),
          if (_e != null) _err(context, _e!),
          _note(context, 'الاستعلام يمر عبر خدمة DNS-over-HTTPS من Cloudflare.'),
        ]),
      );
}

// ───────────── هل الموقع شغال؟ (التطبيق فقط) ─────────────
class SiteCheckPage extends StatefulWidget {
  const SiteCheckPage({super.key});
  @override
  State<SiteCheckPage> createState() => _SiteCheckPageState();
}

class _SiteCheckPageState extends State<SiteCheckPage> {
  final _c = TextEditingController();
  bool _busy = false;
  List<(String, String)>? _rows;
  String? _e;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final u = normalizeUrl(_c.text);
    if (u == null) {
      setState(() => _e = 'اكتب عنوانًا صحيحًا مثل example.com');
      return;
    }
    setState(() {
      _busy = true;
      _e = null;
      _rows = null;
    });
    final sw = Stopwatch()..start();
    try {
      final r = await http.get(u).timeout(const Duration(seconds: 12));
      sw.stop();
      final up = r.statusCode < 500;
      setState(() => _rows = [
            ('الحالة', up ? 'شغّال ✅' : 'الموقع يردّ بخطأ ❌'),
            ('رمز الاستجابة', '${r.statusCode}'),
            ('زمن الاستجابة', '${sw.elapsedMilliseconds} مللي ثانية'),
            ('الخادم', r.headers['server'] ?? '—'),
            ('حجم الصفحة', '${(r.bodyBytes.length / 1024).toStringAsFixed(1)} ك.ب'),
          ]);
    } catch (_) {
      setState(() {
        _rows = null;
        _e = 'الموقع لا يستجيب أو العنوان غير صحيح ❌';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('هل الموقع شغال؟')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _c,
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _run(),
              decoration: const InputDecoration(labelText: 'عنوان الموقع', hintText: 'example.com'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: _busy ? null : _run,
              icon: const Icon(Icons.travel_explore),
              label: const Text('افحص')),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          if (_rows != null) _Rows(_rows!),
          if (_e != null) _err(context, _e!),
        ]),
      );
}
