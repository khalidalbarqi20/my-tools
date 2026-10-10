import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/display_card.dart';

class SensorTestPage extends StatefulWidget {
  const SensorTestPage({super.key});
  @override
  State<SensorTestPage> createState() => _SensorTestPageState();
}

class _SensorTestPageState extends State<SensorTestPage> {
  bool _busy = true;
  List<double>? _acc, _gyro, _mag;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<List<double>?> _one(Stream<List<double>> s) async {
    try {
      return await s.first.timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  Future<void> _probe() async {
    setState(() => _busy = true);
    const p = SensorInterval.normalInterval;
    final r = await Future.wait([
      _one(accelerometerEventStream(samplingPeriod: p).map((e) => [e.x, e.y, e.z])),
      _one(gyroscopeEventStream(samplingPeriod: p).map((e) => [e.x, e.y, e.z])),
      _one(magnetometerEventStream(samplingPeriod: p).map((e) => [e.x, e.y, e.z])),
    ]);
    if (!mounted) return;
    setState(() {
      _acc = r[0];
      _gyro = r[1];
      _mag = r[2];
      _busy = false;
    });
  }

  Widget _card(BuildContext context, String name, String unit, List<double>? v, {String? warn}) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final ok = v != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DisplayCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ok ? Icons.check_circle_outline : Icons.block,
                color: _busy ? cs.onSurfaceVariant : (ok ? Colors.green : cs.error)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text(_busy ? 'جارٍ الفحص...' : (ok ? 'متوفر' : 'غير متوفر'),
                style: TextStyle(color: _busy ? null : (ok ? Colors.green : cs.error))),
          ]),
          if (v != null) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                'X: ${v[0].toStringAsFixed(2)}   Y: ${v[1].toStringAsFixed(2)}   Z: ${v[2].toStringAsFixed(2)}  $unit',
              ),
            ),
            if (warn != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(warn, style: TextStyle(color: cs.error)),
              ),
          ] else if (!_busy)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('هذا المستشعر غير موجود في جهازك أو لا يستجيب، فلا نعرض له نتيجة.'),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    String? magWarn;
    final m = _mag;
    if (m != null) {
      final mag = sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2]);
      if (mag < 10 || mag > 100) {
        magWarn = 'القراءة (${mag.toStringAsFixed(0)} µT) خارج المعتاد (25 إلى 65). ابتعد عن المعادن والمغانط.';
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار المستشعرات'),
        actions: [
          IconButton(
            tooltip: 'إعادة الفحص',
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : _probe,
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _card(context, 'مقياس التسارع', 'م/ث²', _acc),
        _card(context, 'الجيروسكوب (الدوران)', 'راد/ث', _gyro),
        _card(context, 'المغناطيسية (البوصلة)', 'µT', _mag, warn: magWarn),
        Text(
          'حرّك الجهاز وأعد الفحص لترى تغيّر القيم. المستشعر غير المتوفر يظهر بوضوح بدل نتيجة مضللة.',
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
      ]),
    );
  }
}
