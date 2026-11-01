import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../pdf/pdf_common.dart' show OutFile, saveOut, shareOut;
import 'barcode_logic.dart';

const _quiet = 10; // وحدات فراغ على الجانبين

void _paint(ui.Canvas c, double w, double h, String bits, String label, {double textH = 0}) {
  c.drawRect(ui.Rect.fromLTWH(0, 0, w, h), ui.Paint()..color = const Color(0xFFFFFFFF));
  final mod = w / (bits.length + 2 * _quiet);
  final p = ui.Paint()..color = const Color(0xFF000000);
  final barH = h - textH - mod * 6;
  var i = 0;
  while (i < bits.length) {
    if (bits[i] == '1') {
      var j = i;
      while (j < bits.length && bits[j] == '1') {
        j++;
      }
      c.drawRect(ui.Rect.fromLTWH((_quiet + i) * mod, mod * 3, (j - i) * mod, barH), p);
      i = j;
    } else {
      i++;
    }
  }
  if (textH > 0) {
    final tp = TextPainter(
      text: TextSpan(
          text: label,
          style: TextStyle(fontFamily: 'Tajawal', fontSize: textH * 0.7, color: const Color(0xFF000000))),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    tp.paint(c, ui.Offset((w - tp.width) / 2, h - textH - mod * 2 + (textH - tp.height) / 2));
  }
}

class _BarPainter extends CustomPainter {
  final String bits, label;
  const _BarPainter(this.bits, this.label);
  @override
  void paint(Canvas canvas, Size size) => _paint(canvas, size.width, size.height, bits, label, textH: 26);
  @override
  bool shouldRepaint(_BarPainter o) => o.bits != bits || o.label != label;
}

Future<Uint8List> _png(BarcodeResult r) async {
  final scale = 5.0;
  final w = (r.bits.length + 2 * _quiet) * scale;
  const h = 360.0;
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec, ui.Rect.fromLTWH(0, 0, w, h));
  _paint(c, w, h, r.bits, r.label, textH: 60);
  final img = await rec.endRecording().toImage(w.round(), h.round());
  try {
    final d = await img.toByteData(format: ui.ImageByteFormat.png);
    if (d == null) throw Exception('png');
    return d.buffer.asUint8List();
  } finally {
    img.dispose();
  }
}

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});
  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  BarcodeKind _k = BarcodeKind.code128;
  final _c = TextEditingController(text: 'HELLO-123');
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  (BarcodeResult?, String?) _build() {
    if (_c.text.trim().isEmpty) return (null, null);
    try {
      return (buildBarcode(_k, _k == BarcodeKind.code128 ? _c.text : _c.text.trim()), null);
    } on FormatException catch (e) {
      return (null, e.message);
    }
  }

  Future<OutFile?> _file(BarcodeResult r) async {
    setState(() => _busy = true);
    try {
      final safe = r.label.replaceAll(RegExp(r'[^\w\-]+'), '_');
      return OutFile('barcode_${safe.isEmpty ? 'code' : safe}.png', await _png(r), 'image/png');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final (r, err) = _build();
    return Scaffold(
      appBar: AppBar(title: const Text('مولد الباركود')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 8, children: [
          for (final k in BarcodeKind.values)
            ChoiceChip(
              label: Text(barcodeKindNames[k]!),
              selected: _k == k,
              onSelected: (_) => setState(() {
                _k = k;
                _c.text = k == BarcodeKind.code128 ? 'HELLO-123' : (k == BarcodeKind.ean13 ? '629100000000' : '9638507');
              }),
            ),
        ]),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _c,
            onChanged: (_) => setState(() {}),
            keyboardType: _k == BarcodeKind.code128 ? TextInputType.text : TextInputType.number,
            decoration: InputDecoration(
              labelText: _k == BarcodeKind.code128
                  ? 'النص'
                  : (_k == BarcodeKind.ean13 ? 'أرقام EAN-13 (12 أو 13)' : 'أرقام EAN-8 (7 أو 8)'),
            ),
          ),
        ),
        if (err != null)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(err, style: TextStyle(color: t.colorScheme.error))),
        if (r != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(height: 170, child: CustomPaint(painter: _BarPainter(r.bits, r.label))),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final f = await _file(r);
                      if (f != null && context.mounted) await saveOut(context, f);
                    },
              icon: const Icon(Icons.save_alt),
              label: const Text('حفظ كصورة PNG')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final f = await _file(r);
                      if (f != null && context.mounted) await shareOut(context, [f]);
                    },
              icon: const Icon(Icons.share),
              label: const Text('مشاركة')),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
              'Code 128 يقبل الإنجليزية والأرقام والرموز، ويضغط الأرقام الزوجية تلقائيًا. أرقام EAN إن أدخلتها بدون رقم التحقق يُحسب لك. لا تستخدم EAN لمنتجات تُباع فعلًا قبل تسجيل رقمك رسميًا (GS1).',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}
