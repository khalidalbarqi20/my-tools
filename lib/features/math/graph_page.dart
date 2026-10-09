import 'dart:math' as m;
import 'package:flutter/material.dart';
import '../../core/fmt.dart';
import '../calculator/expr.dart';

const _colors = [Color(0xFF2962FF), Color(0xFFE53935), Color(0xFF2E9D4F)];

double? _evalAt(String e, double x) => evalExprWith(e, vars: {'x': x});

double _niceStep(double raw) {
  if (!(raw > 0) || raw.isInfinite) return 1;
  final e = m.pow(10, (m.log(raw) / m.ln10).floor()).toDouble();
  final f = raw / e;
  final nf = f <= 1 ? 1 : (f <= 2 ? 2 : (f <= 5 ? 5 : 10));
  return nf * e;
}

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});
  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  final _fc = [
    TextEditingController(text: 'x^2-4x+3'),
    TextEditingController(),
    TextEditingController(),
  ];
  double _x0 = -10, _x1 = 10, _y0 = -10, _y1 = 10;
  (double, double, double, double) _view0 = (-10, 10, -10, 10);
  Offset _focal0 = Offset.zero;

  @override
  void initState() {
    super.initState();
    _fitY();
  }

  @override
  void dispose() {
    for (final c in _fc) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _funcs => [for (final c in _fc) c.text.trim()];

  void _fitY() {
    var lo = double.infinity, hi = double.negativeInfinity;
    for (final f in _funcs) {
      if (f.isEmpty) continue;
      for (var k = 0; k <= 200; k++) {
        final y = _evalAt(f, _x0 + (_x1 - _x0) * k / 200);
        if (y == null || !y.isFinite || y.abs() > 1e6) continue;
        lo = m.min(lo, y);
        hi = m.max(hi, y);
      }
    }
    if (!lo.isFinite || !hi.isFinite) {
      _y0 = -10;
      _y1 = 10;
      return;
    }
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.12;
    _y0 = lo - pad;
    _y1 = hi + pad;
  }

  void _reset() => setState(() {
        _x0 = -10;
        _x1 = 10;
        _fitY();
      });

  List<double> _roots(double? Function(double) g) {
    const n = 800;
    final res = <double>[];
    double? pv;
    var px = _x0;
    for (var k = 0; k <= n; k++) {
      final x = _x0 + (_x1 - _x0) * k / n;
      final y = g(x);
      if (y == null || !y.isFinite) {
        pv = null;
        continue;
      }
      if (y == 0) {
        res.add(x);
      } else if (pv != null && pv != 0 && pv.sign != y.sign) {
        var lo = px, hi = x;
        for (var it = 0; it < 60; it++) {
          final mid = (lo + hi) / 2;
          final ym = g(mid), yl = g(lo);
          if (ym == null || yl == null) break;
          if (yl.sign == ym.sign) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        final r = (lo + hi) / 2;
        final yr = g(r);
        if (yr != null && yr.abs() < 1e-6) res.add(r); // نتجاهل نقاط الانقطاع (مثل 1/x)
      }
      pv = y;
      px = x;
    }
    final out = <double>[];
    for (final r in res) {
      if (out.isEmpty || (r - out.last).abs() > 1e-6) out.add(r);
    }
    return out;
  }

  List<String> _analysis() {
    final f = _funcs;
    final idx = [for (var i = 0; i < 3; i++) if (f[i].isNotEmpty) i];
    final out = <String>[];
    if (idx.isEmpty) return ['اكتب دالة أولًا'];
    for (final i in idx) {
      final r = _roots((x) => _evalAt(f[i], x)).take(10).toList();
      out.add(r.isEmpty
          ? 'y${i + 1}: لا جذور في المجال الحالي'
          : 'جذور y${i + 1}: ${r.map((v) => 'x = ${fmt(v, 4)}').join('،  ')}');
      final y0 = _evalAt(f[i], 0);
      if (y0 != null && y0.isFinite) out.add('تقاطع y${i + 1} مع المحور y: (0, ${fmt(y0, 4)})');
    }
    for (var a = 0; a < idx.length; a++) {
      for (var b = a + 1; b < idx.length; b++) {
        final i = idx[a], j = idx[b];
        final pts = _roots((x) {
          final p = _evalAt(f[i], x), q = _evalAt(f[j], x);
          return p == null || q == null ? null : p - q;
        }).take(10).toList();
        out.add(pts.isEmpty
            ? 'y${i + 1} و y${j + 1}: لا تقاطع في المجال الحالي'
            : 'تقاطع y${i + 1} و y${j + 1}: ${pts.map((x) => '(${fmt(x, 3)}, ${fmt(_evalAt(f[i], x) ?? 0, 3)})').join('  ')}');
      }
    }
    return out;
  }

  void _showAnalysis() {
    final lines = _analysis();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            const Text('الجذور والتقاطعات في المجال المعروض',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SelectableText(l),
              ),
          ],
        ),
      ),
    );
  }

  void _showTable() {
    final f = _funcs;
    final idx = [for (var i = 0; i < 3; i++) if (f[i].isNotEmpty) i];
    final start = ((_x0 + _x1) / 2).round() - 5;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('جدول القيم'),
        content: SingleChildScrollView(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('x', style: TextStyle(fontWeight: FontWeight.w700))),
                  for (final i in idx)
                    Padding(padding: const EdgeInsets.all(6), child: Text('y${i + 1}', style: TextStyle(fontWeight: FontWeight.w700, color: _colors[i]))),
                ]),
                for (var x = start; x <= start + 10; x++)
                  TableRow(children: [
                    Padding(padding: const EdgeInsets.all(6), child: Text('$x')),
                    for (final i in idx)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(() {
                          final y = _evalAt(f[i], x.toDouble());
                          return y == null || !y.isFinite ? '—' : fmt(y, 4);
                        }()),
                      ),
                  ]),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسم البياني'),
        actions: [
          IconButton(tooltip: 'جدول القيم', icon: const Icon(Icons.table_chart_outlined), onPressed: _showTable),
          IconButton(tooltip: 'إعادة الضبط', icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: TextField(
                  controller: _fc[i],
                  textDirection: TextDirection.ltr,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: 'y${i + 1} = ',
                    prefixStyle: TextStyle(color: _colors[i], fontWeight: FontWeight.w700),
                    hintText: i == 0 ? 'مثال: x^2-4x+3' : 'دالة اختيارية',
                  ),
                ),
              ),
          ]),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            return GestureDetector(
              onDoubleTap: _reset,
              onScaleStart: (d) {
                _view0 = (_x0, _x1, _y0, _y1);
                _focal0 = d.localFocalPoint;
              },
              onScaleUpdate: (d) {
                final (x0, x1, y0, y1) = _view0;
                final sc = d.scale.clamp(0.05, 50.0).toDouble();
                final fx = x0 + _focal0.dx / w * (x1 - x0);
                final fy = y1 - _focal0.dy / h * (y1 - y0);
                final nw = (x1 - x0) / sc, nh = (y1 - y0) / sc;
                if (nw < 1e-6 || nh < 1e-6 || nw > 1e9 || nh > 1e9) return;
                final ux = d.localFocalPoint.dx / w, uy = d.localFocalPoint.dy / h;
                setState(() {
                  _x0 = fx - ux * nw;
                  _x1 = _x0 + nw;
                  _y1 = fy + uy * nh;
                  _y0 = _y1 - nh;
                });
              },
              child: ClipRect(
                child: CustomPaint(
                  size: Size(w, h),
                  painter: _GraphPainter(_funcs, _x0, _x1, _y0, _y1,
                      t.colorScheme.outlineVariant, t.colorScheme.onSurface),
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: FilledButton.tonal(onPressed: _showAnalysis, child: const Text('الجذور والتقاطعات')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(_fitY),
                child: const Text('ملاءمة المحور y'),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('اسحب للتحريك، واقرص للتكبير، ونقرتان للإعادة',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<String> funcs;
  final double x0, x1, y0, y1;
  final Color grid, text;
  _GraphPainter(this.funcs, this.x0, this.x1, this.y0, this.y1, this.grid, this.text);

  void _label(Canvas canvas, String s, Offset o) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: text.withValues(alpha: 0.75), fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!(x1 > x0) || !(y1 > y0) || size.width <= 0 || size.height <= 0) return;
    final w = size.width, h = size.height;
    double px(double x) => (x - x0) / (x1 - x0) * w;
    double py(double y) => h - (y - y0) / (y1 - y0) * h;
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final ap = Paint()
      ..color = text.withValues(alpha: 0.7)
      ..strokeWidth = 1.6;
    final sx = _niceStep((x1 - x0) / 6), sy = _niceStep((y1 - y0) / 6);
    final ox = px(0).clamp(0.0, m.max(0.0, w - 28)).toDouble();
    final oy = py(0).clamp(12.0, m.max(12.0, h)).toDouble();
    var count = 0;
    for (var k = (x0 / sx).ceil(); k * sx <= x1 && count < 200; k++, count++) {
      final x = k * sx, p = px(x);
      canvas.drawLine(Offset(p, 0), Offset(p, h), x == 0 ? ap : gp);
      if (x != 0) _label(canvas, fmt(x, 4), Offset(p + 2, oy - 12));
    }
    count = 0;
    for (var k = (y0 / sy).ceil(); k * sy <= y1 && count < 200; k++, count++) {
      final y = k * sy, p = py(y);
      canvas.drawLine(Offset(0, p), Offset(w, p), y == 0 ? ap : gp);
      if (y != 0) _label(canvas, fmt(y, 4), Offset(ox + 3, p - 12));
    }
    canvas.clipRect(Offset.zero & size);
    final samples = (w / 1.5).ceil();
    for (var i = 0; i < funcs.length; i++) {
      final f = funcs[i];
      if (f.isEmpty) continue;
      final path = Path();
      var pen = false;
      var prev = 0.0;
      for (var k = 0; k <= samples; k++) {
        final x = x0 + (x1 - x0) * k / samples;
        final y = evalExprWith(f, vars: {'x': x});
        if (y == null || !y.isFinite || y.abs() > 1e9) {
          pen = false;
          continue;
        }
        final o = Offset(px(x), py(y));
        if (!pen || (o.dy - prev).abs() > h * 3) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
        prev = o.dy;
        pen = true;
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round
          ..color = _colors[i % _colors.length],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => true;
}
