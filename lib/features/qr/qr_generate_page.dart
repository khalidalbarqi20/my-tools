import 'package:flutter/material.dart';
import '../pdf/pdf_common.dart' show OutFile, saveOut, shareOut;
import 'qr_logic.dart';
import 'qr_render.dart';

enum _T { url, text, wifi, phone, email, sms, contact }

const _titles = {
  _T.url: 'رابط',
  _T.text: 'نص',
  _T.wifi: 'Wi-Fi',
  _T.phone: 'هاتف',
  _T.email: 'بريد',
  _T.sms: 'رسالة',
  _T.contact: 'جهة اتصال',
};

class QrGeneratePage extends StatefulWidget {
  const QrGeneratePage({super.key});
  @override
  State<QrGeneratePage> createState() => _QrGeneratePageState();
}

class _QrGeneratePageState extends State<QrGeneratePage> {
  _T _t = _T.url;
  String _sec = 'WPA';
  bool _hidden = false;
  final Map<String, TextEditingController> _c = {
    for (final k in ['a', 'b', 'c', 'd']) k: TextEditingController()
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _switch(_T t) {
    for (final c in _c.values) {
      c.clear();
    }
    setState(() => _t = t);
  }

  List<(String, String, bool)> _fields() => switch (_t) {
        _T.url => [('a', 'الرابط', false)],
        _T.text => [('a', 'النص', true)],
        _T.wifi => [('a', 'اسم الشبكة', false), ('b', 'كلمة المرور', false)],
        _T.phone => [('a', 'رقم الهاتف', false)],
        _T.email => [
            ('a', 'البريد الإلكتروني', false),
            ('b', 'الموضوع (اختياري)', false),
            ('c', 'الرسالة (اختياري)', true),
          ],
        _T.sms => [('a', 'رقم الهاتف', false), ('b', 'الرسالة', true)],
        _T.contact => [
            ('a', 'الاسم', false),
            ('b', 'الهاتف (اختياري)', false),
            ('c', 'البريد (اختياري)', false),
            ('d', 'الجهة (اختياري)', false),
          ],
      };

  String? _content() {
    String v(String k) => _c[k]!.text;
    try {
      return switch (_t) {
        _T.url => normalizeUrl(v('a')),
        _T.text => v('a').trim().isEmpty ? null : v('a'),
        _T.wifi => buildWifi(ssid: v('a'), pass: v('b'), sec: _sec, hidden: _hidden),
        _T.phone => buildPhone(v('a')),
        _T.email => buildEmail(v('a'), subject: v('b'), body: v('c')),
        _T.sms => buildSms(v('a'), body: v('b')),
        _T.contact =>
          buildContact(name: v('a'), phone: v('b'), email: v('c'), org: v('d')),
      };
    } on FormatException {
      return null;
    }
  }

  Future<OutFile?> _file(String data) async {
    final img = makeQr(data);
    if (img == null) return null;
    final png = await qrPng(img);
    return OutFile(
        'qr_${DateTime.now().millisecondsSinceEpoch}.png', png, 'image/png');
  }

  Future<void> _save(String data) async {
    final f = await _file(data);
    if (f == null || !mounted) return;
    await saveOut(context, f);
  }

  Future<void> _share(String data) async {
    final f = await _file(data);
    if (f == null || !mounted) return;
    await shareOut(context, [f]);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final data = _content();
    final img = data == null ? null : makeQr(data);
    final tooLong = data != null && img == null;
    final w = MediaQuery.sizeOf(context).width;
    final side = (w - 80).clamp(160.0, 300.0).toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('مولد QR')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final x in _T.values)
              ChoiceChip(
                label: Text(_titles[x]!),
                selected: _t == x,
                onSelected: (_) => _switch(x),
              ),
          ]),
          const SizedBox(height: 16),
          for (final f in _fields()) ...[
            TextField(
              controller: _c[f.$1],
              onChanged: (_) => setState(() {}),
              minLines: f.$3 ? 3 : 1,
              maxLines: f.$3 ? 6 : 1,
              keyboardType: f.$3 ? TextInputType.multiline : TextInputType.text,
              decoration: InputDecoration(labelText: f.$2),
            ),
            const SizedBox(height: 12),
          ],
          if (_t == _T.wifi) ...[
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'WPA', label: Text('WPA/WPA2')),
                ButtonSegment(value: 'WEP', label: Text('WEP')),
                ButtonSegment(value: 'nopass', label: Text('بدون')),
              ],
              selected: {_sec},
              onSelectionChanged: (s) => setState(() => _sec = s.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('شبكة مخفية'),
              value: _hidden,
              onChanged: (v) => setState(() => _hidden = v),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: side + 32,
              height: side + 32,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: img == null
                  ? Center(
                      child: Text(
                        tooLong
                            ? 'البيانات طويلة جدًا لرمز QR'
                            : 'أدخل البيانات ليظهر الرمز هنا',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.outline),
                      ),
                    )
                  : CustomPaint(painter: QrCodePainter(img), size: Size(side, side)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: img == null ? null : () => _save(data!),
                icon: const Icon(Icons.download),
                label: const Text('حفظ الصورة'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: img == null ? null : () => _share(data!),
                icon: const Icon(Icons.share),
                label: const Text('مشاركة'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text('الرمز يُنشأ على جهازك بدون إنترنت، ويُحفظ أسود على أبيض ليسهل مسحه.',
              style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
