import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:torch_light/torch_light.dart';
import '../../core/display_card.dart';
import 'device_logic.dart';

List<double> _lowPass(List<double>? prev, List<double> cur, double alpha) {
  if (prev == null) return cur;
  return [for (var i = 0; i < 3; i++) prev[i] + alpha * (cur[i] - prev[i])];
}

// ───────────────────────── الكشاف ─────────────────────────
class FlashlightPage extends StatefulWidget {
  const FlashlightPage({super.key});
  @override
  State<FlashlightPage> createState() => _FlashlightPageState();
}

class _FlashlightPageState extends State<FlashlightPage> {
  bool _on = false, _checked = false, _available = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    if (_on) _off();
    super.dispose();
  }

  static Future<void> _off() async {
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }

  Future<void> _check() async {
    var ok = false;
    try {
      ok = await TorchLight.isTorchAvailable();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _available = ok;
      _checked = true;
    });
  }

  Future<void> _toggle() async {
    try {
      if (_on) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      if (!mounted) return;
      setState(() {
        _on = !_on;
        _err = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _err =
          'تعذّر تشغيل الكشاف. أغلق أي تطبيق كاميرا مفتوح ثم حاول مرة أخرى.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('الكشاف')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!_checked)
              const CircularProgressIndicator()
            else if (!_available)
              Text('هذا الجهاز لا يحتوي على كشاف متاح.',
                  textAlign: TextAlign.center, style: t.textTheme.titleMedium)
            else ...[
              GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _on ? Colors.amber : cs.surfaceContainerHighest,
                    boxShadow: _on
                        ? [
                            BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 6)
                          ]
                        : null,
                  ),
                  child: Icon(
                    _on ? Icons.flashlight_on : Icons.flashlight_off,
                    size: 72,
                    color: _on ? Colors.black87 : cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(_on ? 'مشغّل' : 'مطفأ', style: t.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('اضغط الدائرة للتشغيل أو الإطفاء',
                  style: t.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
            if (_err != null) ...[
              const SizedBox(height: 16),
              Text(_err!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error)),
            ],
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── البوصلة ─────────────────────────
class CompassPage extends StatefulWidget {
  const CompassPage({super.key});
  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  StreamSubscription<AccelerometerEvent>? _aSub;
  StreamSubscription<MagnetometerEvent>? _mSub;
  List<double>? _a, _m;
  double? _heading;
  bool _err = false;

  @override
  void initState() {
    super.initState();
    _aSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen((e) => _a = _lowPass(_a, [e.x, e.y, e.z], 0.15),
            onError: _onErr);
    _mSub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen((e) {
      _m = _lowPass(_m, [e.x, e.y, e.z], 0.15);
      final a = _a, m = _m;
      if (a == null || m == null) return;
      final h = compassHeading(a[0], a[1], a[2], m[0], m[1], m[2]);
      if (mounted) setState(() => _heading = h);
    }, onError: _onErr);
  }

  void _onErr(Object _) {
    if (mounted) setState(() => _err = true);
  }

  @override
  void dispose() {
    _aSub?.cancel();
    _mSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final h = _heading;
    return Scaffold(
      appBar: AppBar(title: const Text('البوصلة')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (_err)
          Text('هذا الجهاز لا يدعم مستشعرات البوصلة.',
              textAlign: TextAlign.center, style: TextStyle(color: cs.error))
        else ...[
          Center(
            child: Column(children: [
              Text(h == null ? '—' : directionAr(h),
                  style: t.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(h == null ? 'جارٍ القراءة...' : '${h.round()}°',
                    style: t.textTheme.titleLarge),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 300,
              height: 320,
              child: Stack(alignment: Alignment.topCenter, children: [
                Positioned(
                  top: 24,
                  child: Transform.rotate(
                    angle: h == null ? 0 : -h * pi / 180,
                    child: CustomPaint(
                      size: const Size.square(280),
                      painter: _DialPainter(cs.onSurface, cs.outline),
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: 48, color: cs.primary),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الاتجاه بالنسبة للشمال المغناطيسي. ضع الجهاز مسطحًا وبعيدًا عن المعادن والمغانط. '
            'إذا بدت القراءة غير دقيقة حرّك الجهاز في الهواء على شكل رقم 8.',
            style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ]),
    );
  }
}

class _DialPainter extends CustomPainter {
  final Color fg, line;
  _DialPainter(this.fg, this.line);

  void _label(Canvas canvas, String s, Offset c, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              color: color, fontSize: 22, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
        c,
        r - 1,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final tick = Paint()
      ..color = fg.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    for (var d = 0; d < 360; d += 10) {
      final a = d * pi / 180;
      final dir = Offset(sin(a), -cos(a));
      final len = d % 90 == 0 ? 0.0 : (d % 30 == 0 ? 16.0 : 8.0);
      if (len > 0) canvas.drawLine(c + dir * (r - len), c + dir * r, tick);
    }
    _label(canvas, 'ش', c + const Offset(0, -1) * (r - 30), Colors.red);
    _label(canvas, 'ق', c + const Offset(1, 0) * (r - 30), fg);
    _label(canvas, 'ج', c + const Offset(0, 1) * (r - 30), fg);
    _label(canvas, 'غ', c + const Offset(-1, 0) * (r - 30), fg);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.fg != fg || old.line != line;
}

// ───────────────────────── الميزان ─────────────────────────
class LevelPage extends StatefulWidget {
  const LevelPage({super.key});
  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  StreamSubscription<AccelerometerEvent>? _sub;
  List<double>? _a;
  bool _err = false;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen((e) {
      _a = _lowPass(_a, [e.x, e.y, e.z], 0.2);
      if (mounted) setState(() {});
    }, onError: (Object _) {
      if (mounted) setState(() => _err = true);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final a = _a;
    double tx = 0, ty = 0;
    if (a != null) (tx, ty) = levelAngles(a[0], a[1], a[2]);
    final flat = a != null && tx.abs() < 1 && ty.abs() < 1;
    return Scaffold(
      appBar: AppBar(title: const Text('الميزان')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (_err)
          Text('هذا الجهاز لا يدعم مستشعر الميزان.',
              textAlign: TextAlign.center, style: TextStyle(color: cs.error))
        else ...[
          DisplayCard(
            child: Column(children: [
              Center(
                child: CustomPaint(
                  size: const Size.square(260),
                  painter: _LevelPainter(
                    (tx / 15).clamp(-1.0, 1.0).toDouble(),
                    (ty / 15).clamp(-1.0, 1.0).toDouble(),
                    flat ? Colors.green : cs.primary,
                    cs.outline,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  a == null
                      ? '—'
                      : 'X: ${tx.toStringAsFixed(1)}°     Y: ${ty.toStringAsFixed(1)}°',
                  style: t.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                a == null ? 'جارٍ القراءة...' : (flat ? 'مستوٍ' : 'مائل'),
                style: t.textTheme.titleMedium?.copyWith(
                    color: flat ? Colors.green : null,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Text(
            'ضع الجهاز مسطحًا على السطح المراد فحصه. الفقاعة تتجه نحو الجهة الأعلى. '
            'الدقة تقريبية وتعتمد على معايرة مستشعر الجهاز.',
            style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ]),
    );
  }
}

class _LevelPainter extends CustomPainter {
  final double dx, dy; // -1..1 (الجهة الأعلى)
  final Color bubble, line;
  _LevelPainter(this.dx, this.dy, this.bubble, this.line);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r - 1, stroke);
    canvas.drawCircle(c, 26, stroke);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy),
        stroke..strokeWidth = 1);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), stroke);
    const br = 22.0;
    final reach = r - br - 4;
    final pos = c + Offset(dx * reach, -dy * reach);
    canvas.drawCircle(pos, br, Paint()..color = bubble.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant _LevelPainter old) =>
      old.dx != dx || old.dy != dy || old.bubble != bubble || old.line != line;
}
