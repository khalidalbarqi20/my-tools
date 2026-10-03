import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../image/image_common.dart' show ImgDims, imgError;
import 'qr_prepare.dart';

class _Overlay extends CustomPainter {
  final double l, t, r, b;
  _Overlay(this.l, this.t, this.r, this.b);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
        size.width * l, size.height * t, size.width * r, size.height * b);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black54);
    canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white);
    for (final p in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      canvas.drawCircle(p, 10, Paint()..color = Colors.white);
      canvas.drawCircle(
          p,
          10,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.black38);
    }
  }

  @override
  bool shouldRepaint(_Overlay o) => o.l != l || o.t != t || o.r != r || o.b != b;
}

class QrCropPage extends StatefulWidget {
  final Uint8List bytes;
  final ImgDims dims;
  const QrCropPage({super.key, required this.bytes, required this.dims});
  @override
  State<QrCropPage> createState() => _QrCropPageState();
}

class _QrCropPageState extends State<QrCropPage> {
  double _l = 0, _t = 0, _r = 1, _b = 1;
  int _turns = 0;
  bool _invert = false;
  int? _drag; // 0..3 زوايا، 4 تحريك
  bool _busy = false;
  String? _err;

  static const _inv = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0,
  ]);

  double _c(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

  void _start(Offset p, Size s) {
    final pts = [
      Offset(_l * s.width, _t * s.height),
      Offset(_r * s.width, _t * s.height),
      Offset(_l * s.width, _b * s.height),
      Offset(_r * s.width, _b * s.height),
    ];
    _drag = null;
    var best = 44.0;
    for (var i = 0; i < 4; i++) {
      final d = (pts[i] - p).distance;
      if (d < best) {
        best = d;
        _drag = i;
      }
    }
    if (_drag == null && Rect.fromLTRB(pts[0].dx, pts[0].dy, pts[3].dx, pts[3].dy).contains(p)) {
      _drag = 4;
    }
  }

  void _update(Offset d, Size s) {
    final dx = d.dx / s.width, dy = d.dy / s.height;
    const m = 0.08;
    setState(() {
      switch (_drag) {
        case 0:
          _l = _c(_l + dx, 0, _r - m);
          _t = _c(_t + dy, 0, _b - m);
        case 1:
          _r = _c(_r + dx, _l + m, 1);
          _t = _c(_t + dy, 0, _b - m);
        case 2:
          _l = _c(_l + dx, 0, _r - m);
          _b = _c(_b + dy, _t + m, 1);
        case 3:
          _r = _c(_r + dx, _l + m, 1);
          _b = _c(_b + dy, _t + m, 1);
        case 4:
          final w = _r - _l, h = _b - _t;
          final nl = _c(_l + dx, 0, 1 - w);
          final nt = _c(_t + dy, 0, 1 - h);
          _l = nl;
          _r = nl + w;
          _t = nt;
          _b = nt + h;
        default:
          break;
      }
    });
  }

  void _reset() => setState(() {
        _l = 0;
        _t = 0;
        _r = 1;
        _b = 1;
      });

  Future<void> _done() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final out = await prepareForDecode(widget.bytes,
          l: _l, t: _t, r: _r, b: _b, turns: _turns, invert: _invert);
      if (mounted) Navigator.pop(context, out);
    } catch (e) {
      if (mounted) {
        setState(() {
          _err = imgError(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final d = widget.dims;
    final ar = _turns.isOdd ? d.h / d.w : d.w / d.h;
    Widget img = Image.memory(widget.bytes,
        fit: BoxFit.fill, cacheWidth: 1400, gaplessPlayback: true);
    if (_invert) img = ColorFiltered(colorFilter: _inv, child: img);
    return Scaffold(
      appBar: AppBar(title: const Text('قص الصورة قبل القراءة')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('حرّك الزوايا لتحديد الرمز فقط، واسحب داخل الإطار لتحريكه.',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: AspectRatio(
                  aspectRatio: ar,
                  child: LayoutBuilder(builder: (c, cons) {
                    final s = Size(cons.maxWidth, cons.maxHeight);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (e) => _start(e.localPosition, s),
                      onPanUpdate: (e) => _update(e.delta, s),
                      onPanEnd: (_) => _drag = null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(fit: StackFit.expand, children: [
                          RotatedBox(quarterTurns: _turns, child: img),
                          CustomPaint(painter: _Overlay(_l, _t, _r, _b)),
                        ]),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                    onPressed: () => setState(() => _turns = (_turns + 3) % 4),
                    icon: const Icon(Icons.rotate_left),
                    label: const Text('يسار')),
                OutlinedButton.icon(
                    onPressed: () => setState(() => _turns = (_turns + 1) % 4),
                    icon: const Icon(Icons.rotate_right),
                    label: const Text('يمين')),
                FilterChip(
                    label: const Text('عكس الألوان'),
                    selected: _invert,
                    onSelected: (v) => setState(() => _invert = v)),
                TextButton(onPressed: _reset, child: const Text('الصورة كاملة')),
              ],
            ),
          ),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton.icon(
              onPressed: _busy ? null : _done,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.qr_code_scanner),
              label: const Text('قراءة الرمز'),
            ),
          ),
        ]),
      ),
    );
  }
}
