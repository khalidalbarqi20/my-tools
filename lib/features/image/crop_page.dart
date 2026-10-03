import 'package:flutter/material.dart';
import '../pdf/pdf_common.dart' show OutFile, ResultList, baseName;
import 'image_common.dart';
import 'image_logic.dart';
import 'image_ops.dart';

class _CropPainter extends CustomPainter {
  final double l, t, r, b;
  _CropPainter(this.l, this.t, this.r, this.b);
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
  }

  @override
  bool shouldRepaint(_CropPainter o) =>
      o.l != l || o.t != t || o.r != r || o.b != b;
}

class CropPage extends StatefulWidget {
  const CropPage({super.key});
  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  LoadedImage? _img;
  double _l = 0, _t = 0, _r = 1, _b = 1;
  String _fmt = 'jpg';
  bool _busy = false;
  String? _err;
  List<OutFile> _out = [];

  Future<void> _pick() async {
    try {
      final x = await pickOneImage();
      if (x == null || !mounted) return;
      setState(() {
        _img = x;
        _l = 0;
        _t = 0;
        _r = 1;
        _b = 1;
        _out = [];
        _err = null;
      });
    } catch (e) {
      if (mounted) setState(() => _err = imgError(e));
    }
  }

  void _preset(int rw, int rh) {
    final d = _img!.dims;
    final (l, t, r, b) = centeredAspect(d.w, d.h, rw, rh);
    setState(() {
      _l = l;
      _t = t;
      _r = r;
      _b = b;
      _out = [];
    });
  }

  Future<void> _run() async {
    final x = _img;
    if (x == null) return;
    setState(() {
      _busy = true;
      _err = null;
      _out = [];
    });
    try {
      final f = fmtFromKey(_fmt);
      final data = await cropEncode(x.file.bytes, _l, _t, _r, _b, f, 90);
      final o = OutFile(
          '${baseName(x.file.name)}_crop.${extOf(f)}', data, mimeOf(f));
      if (mounted) setState(() => _out = [o]);
    } catch (e) {
      if (mounted) setState(() => _err = imgError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final x = _img;
    final rect =
        x == null ? null : cropRect(x.dims.w, x.dims.h, _l, _t, _r, _b);
    return Scaffold(
      appBar: AppBar(title: const Text('قص الصورة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(x == null ? 'اختيار صورة' : 'تغيير الصورة'),
          ),
          if (x != null && rect != null) ...[
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: AspectRatio(
                  aspectRatio: x.dims.w / x.dims.h,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.memory(x.file.bytes, fit: BoxFit.fill, cacheWidth: 1000),
                    CustomPaint(painter: _CropPainter(_l, _t, _r, _b)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('الحجم الناتج: ${rect.$3} × ${rect.$4} بكسل'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ActionChip(
                  label: const Text('الكل'),
                  onPressed: () => setState(() {
                        _l = 0;
                        _t = 0;
                        _r = 1;
                        _b = 1;
                        _out = [];
                      })),
              for (final p in const [
                ('1:1', 1, 1),
                ('4:3', 4, 3),
                ('3:4', 3, 4),
                ('16:9', 16, 9),
                ('9:16', 9, 16),
              ])
                ActionChip(label: Text(p.$1), onPressed: () => _preset(p.$2, p.$3)),
            ]),
            const SizedBox(height: 8),
            const Text('الحدود الأفقية (يسار - يمين)'),
            Directionality(
              textDirection: TextDirection.ltr,
              child: RangeSlider(
                values: RangeValues(_l, _r),
                onChanged: (v) {
                  if (v.end - v.start < 0.05) return;
                  setState(() {
                    _l = v.start;
                    _r = v.end;
                    _out = [];
                  });
                },
              ),
            ),
            const Text('الحدود العمودية (أعلى - أسفل)'),
            Directionality(
              textDirection: TextDirection.ltr,
              child: RangeSlider(
                values: RangeValues(_t, _b),
                onChanged: (v) {
                  if (v.end - v.start < 0.05) return;
                  setState(() {
                    _t = v.start;
                    _b = v.end;
                    _out = [];
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final k in ['jpg', 'png', 'webp'])
                  ButtonSegment(value: k, label: Text(k.toUpperCase()))
              ],
              selected: {_fmt},
              onSelectionChanged: (s) => setState(() => _fmt = s.first),
            ),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: _busy ? null : _run, child: const Text('قص الصورة')),
          ],
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator()),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
            ),
          ResultList(_out),
        ],
      ),
    );
  }
}
