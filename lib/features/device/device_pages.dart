import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/display_card.dart';
import 'device_logic.dart';

typedef _Row = MapEntry<String, String>;

// ───────────────────────── معلومات الجهاز ─────────────────────────
class DeviceInfoPage extends StatefulWidget {
  const DeviceInfoPage({super.key});
  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  List<_Row> _hw = [];
  List<_Row> _bat = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final hw = <_Row>[];
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final i = await DeviceInfoPlugin().androidInfo;
        hw.add(_Row('الشركة', i.manufacturer));
        hw.add(_Row('العلامة', i.brand));
        hw.add(_Row('الموديل', i.model));
        hw.add(_Row('اسم الجهاز', i.device));
        hw.add(_Row('إصدار النظام',
            androidLabel(i.version.release, i.version.sdkInt)));
        hw.add(_Row('المعالج (ABI)', i.supportedAbis.join(', ')));
        hw.add(_Row('جهاز حقيقي', i.isPhysicalDevice ? 'نعم' : 'محاكي'));
      } else {
        hw.add(const _Row('ملاحظة', 'قراءة معلومات الجهاز متاحة على أندرويد فقط'));
      }
    } catch (_) {
      hw.add(const _Row('ملاحظة', 'تعذّر قراءة معلومات الجهاز'));
    }
    final bat = <_Row>[];
    try {
      final b = Battery();
      final level = await b.batteryLevel;
      final state = await b.batteryState;
      bat.add(_Row('مستوى البطارية', '$level%'));
      bat.add(_Row('حالة البطارية', batteryStateAr(state.name)));
    } catch (_) {
      bat.add(const _Row('البطارية', 'غير متاحة على هذا الجهاز'));
    }
    if (!mounted) return;
    setState(() {
      _hw = hw;
      _bat = bat;
      _loading = false;
    });
  }

  Widget _section(String title, List<_Row> rows) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DisplayCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: t.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(r.key,
                      style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: SelectableText(r.value, textAlign: TextAlign.end),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final dpr = mq.devicePixelRatio;
    final wPx = mq.size.width * dpr, hPx = mq.size.height * dpr;
    final screen = <_Row>[
      _Row('الدقة', '${wPx.round()} × ${hPx.round()} بكسل'),
      _Row('الكثافة', dpiLabel(dpr)),
      _Row('حجم الشاشة', inchesLabel(screenInches(wPx, hPx, dpr))),
    ];
    final all = [..._hw, ...screen, ..._bat];
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات الجهاز'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            tooltip: 'نسخ',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text: all.map((e) => '${e.key}: ${e.value}').join('\n')));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('تم النسخ')));
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (_loading) const LinearProgressIndicator(),
        if (_hw.isNotEmpty) _section('الجهاز', _hw),
        _section('الشاشة', screen),
        if (_bat.isNotEmpty) _section('البطارية', _bat),
      ]),
    );
  }
}

// ───────────────────────── اختبار الشاشة ─────────────────────────
class ScreenTestPage extends StatefulWidget {
  const ScreenTestPage({super.key});
  @override
  State<ScreenTestPage> createState() => _ScreenTestPageState();
}

class _ScreenTestPageState extends State<ScreenTestPage> {
  static const _colors = <Color>[
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Color(0xFF808080),
  ];
  int _i = 0, _taps = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors[_i];
    final fg = c.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Scaffold(
      backgroundColor: c,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _i = (_i + 1) % _colors.length;
          _taps++;
        }),
        child: SizedBox.expand(
          child: Center(
            child: _taps < 3
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'اضغط لتغيير اللون\nابحث عن بقع ميتة أو خطوط أو تدرجات غير طبيعية\nاسحب من الحافة أو اضغط رجوع للخروج',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: fg, fontSize: 16, height: 1.6),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── اختبار اللمس ─────────────────────────
class TouchTestPage extends StatefulWidget {
  const TouchTestPage({super.key});
  @override
  State<TouchTestPage> createState() => _TouchTestPageState();
}

class _TouchTestPageState extends State<TouchTestPage> {
  final Map<int, Offset> _active = {};
  final List<Offset> _trail = [];
  int _max = 0;

  void _update(PointerEvent e) => setState(() {
        _active[e.pointer] = e.localPosition;
        _trail.add(e.localPosition);
        if (_trail.length > 3000) _trail.removeRange(0, 500);
        _max = max(_max, _active.length);
      });

  void _up(PointerEvent e) => setState(() => _active.remove(e.pointer));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار اللمس'),
        actions: [
          IconButton(
            tooltip: 'مسح',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() {
              _trail.clear();
              _max = 0;
            }),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'نقاط اللمس الآن: ${_active.length}   •   الأقصى: $_max\nمرّر إصبعك على كل أجزاء الشاشة، وجرّب أكثر من إصبع',
            textAlign: TextAlign.center,
            style: t.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _update,
            onPointerMove: _update,
            onPointerUp: _up,
            onPointerCancel: _up,
            child: ClipRect(
              child: CustomPaint(
                painter: _TouchPainter(
                  List.of(_trail),
                  _active.values.toList(),
                  t.colorScheme.primary,
                  t.colorScheme.surfaceContainerHighest,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TouchPainter extends CustomPainter {
  final List<Offset> trail, active;
  final Color color, bg;
  _TouchPainter(this.trail, this.active, this.color, this.bg);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg.withValues(alpha: 0.4));
    final p = Paint()..color = color.withValues(alpha: 0.35);
    for (final o in trail) {
      canvas.drawCircle(o, 6, p);
    }
    final a = Paint()..color = color;
    for (final o in active) {
      canvas.drawCircle(o, 34, a);
    }
  }

  @override
  bool shouldRepaint(covariant _TouchPainter old) => true;
}

// ───────────────────────── اختبار الاهتزاز ─────────────────────────
class VibrationTestPage extends StatelessWidget {
  const VibrationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget btn(String label, IconData icon, VoidCallback f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton.tonalIcon(
            onPressed: f,
            icon: Icon(icon),
            label: Text(label),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار الاهتزاز')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        btn('اهتزاز خفيف', Icons.vibration, HapticFeedback.lightImpact),
        btn('اهتزاز متوسط', Icons.vibration, HapticFeedback.mediumImpact),
        btn('اهتزاز قوي', Icons.vibration, HapticFeedback.heavyImpact),
        btn('اهتزاز عادي', Icons.vibration, HapticFeedback.vibrate),
        const SizedBox(height: 8),
        Text(
          'إذا لم تشعر باهتزاز: تأكد أن اهتزاز اللمس مفعّل في إعدادات الهاتف '
          'وأن الجهاز ليس في وضع توفير الطاقة. بعض الأجهزة لا تدعم كل الأنماط.',
          style: t.textTheme.bodySmall
              ?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
      ]),
    );
  }
}
