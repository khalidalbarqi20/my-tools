import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/display_card.dart';
import '../../core/num_parse.dart';
import 'time_logic.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  final _h = TextEditingController(text: '0');
  final _m = TextEditingController(text: '5');
  final _s = TextEditingController(text: '0');
  final _sw = Stopwatch();
  Timer? _tick;
  Duration _total = Duration.zero;
  Duration _base = Duration.zero; // المتبقي عند آخر إيقاف
  bool _active = false;
  bool _ringing = false;

  @override
  void dispose() {
    _ringing = false;
    _tick?.cancel();
    _h.dispose();
    _m.dispose();
    _s.dispose();
    super.dispose();
  }

  Duration get _left {
    final l = _base - _sw.elapsed;
    return l.isNegative ? Duration.zero : l;
  }

  int _n(TextEditingController c) {
    final v = parseNum(c.text)?.round() ?? 0;
    return v < 0 ? 0 : v;
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _preset(int minutes) => setState(() {
        _h.text = '${minutes ~/ 60}';
        _m.text = '${minutes % 60}';
        _s.text = '0';
      });

  void _start() {
    final d = Duration(hours: _n(_h), minutes: _n(_m), seconds: _n(_s));
    if (d <= Duration.zero) {
      _toast('حدد وقتًا أكبر من صفر');
      return;
    }
    if (d > const Duration(hours: 99)) {
      _toast('الحد الأقصى 99 ساعة');
      return;
    }
    _total = d;
    _base = d;
    _sw.reset();
    _active = true;
    _run();
  }

  void _run() {
    _sw.start();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      if (_left <= Duration.zero) {
        _finish();
      } else {
        setState(() {});
      }
    });
    setState(() {});
  }

  void _pause() {
    _base = _left;
    _sw.stop();
    _sw.reset();
    _tick?.cancel();
    setState(() {});
  }

  void _reset() {
    _tick?.cancel();
    _sw.stop();
    _sw.reset();
    setState(() => _active = false);
  }

  Future<void> _buzz() async {
    for (var i = 0; i < 12 && _ringing && mounted; i++) {
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }

  Future<void> _finish() async {
    _tick?.cancel();
    _sw.stop();
    _sw.reset();
    _base = Duration.zero;
    _ringing = true;
    setState(() {});
    _buzz();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('انتهى الوقت ⏰'),
        content: Text('انتهى مؤقت ${fmtClock(_total)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إيقاف')),
        ],
      ),
    );
    _ringing = false;
    if (mounted) setState(() => _active = false);
  }

  Widget _field(TextEditingController c, String label) => Expanded(
        child: TextField(
          controller: c,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final running = _sw.isRunning;
    return Scaffold(
      appBar: AppBar(title: const Text('مؤقت')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_active) ...[
            Row(children: [
              _field(_h, 'ساعات'),
              const SizedBox(width: 10),
              _field(_m, 'دقائق'),
              const SizedBox(width: 10),
              _field(_s, 'ثواني'),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in const [1, 5, 10, 15, 30, 60])
                ActionChip(
                    label: Text(m == 60 ? 'ساعة' : '$m د'),
                    onPressed: () => _preset(m)),
            ]),
            const SizedBox(height: 20),
            FilledButton(onPressed: _start, child: const Text('ابدأ المؤقت')),
          ] else ...[
            const SizedBox(height: 8),
            Center(
              child: TimeRing(
                value: _total.inMilliseconds == 0
                    ? 0
                    : _left.inMilliseconds / _total.inMilliseconds,
                color: cs.primary,
                child: Text(
                  fmtClock(_left),
                  style: t.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: _reset, child: const Text('إلغاء'))),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: running ? _pause : _run,
                  child: Text(running ? 'إيقاف مؤقت' : 'متابعة'),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 24),
          Text('المؤقت يعمل والتطبيق مفتوح. التنبيه عند إغلاق التطبيق يُضاف لاحقًا.',
              style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
