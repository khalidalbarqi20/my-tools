import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/display_card.dart';
import 'time_logic.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});
  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  String _preset = '25';
  PomoPhase _phase = PomoPhase.work;
  int _done = 0;
  final _sw = Stopwatch();
  Timer? _tick;
  late Duration _base = _phaseTotal;

  Duration get _phaseTotal => Duration(minutes: pomoMinutes(_preset, _phase));
  Duration get _left {
    final l = _base - _sw.elapsed;
    return l.isNegative ? Duration.zero : l;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _run() {
    _sw.start();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      if (_left <= Duration.zero) {
        _next(count: true);
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

  void _next({required bool count}) {
    _tick?.cancel();
    _sw.stop();
    _sw.reset();
    if (count) {
      HapticFeedback.heavyImpact();
      if (_phase == PomoPhase.work) _done++;
    }
    _phase = pomoNext(_phase, _done);
    _base = _phaseTotal;
    setState(() {});
    if (count) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_phase == PomoPhase.work
              ? 'انتهت الاستراحة، جاهز للتركيز؟'
              : 'أحسنت! خذ استراحة')));
    }
  }

  void _reset() {
    _tick?.cancel();
    _sw.stop();
    _sw.reset();
    _phase = PomoPhase.work;
    _done = 0;
    _base = _phaseTotal;
    setState(() {});
  }

  void _setPreset(String v) {
    if (_sw.isRunning) return;
    _preset = v;
    _base = _phaseTotal;
    setState(() {});
  }

  String get _label => switch (_phase) {
        PomoPhase.work => 'وقت التركيز',
        PomoPhase.shortBreak => 'استراحة قصيرة',
        PomoPhase.longBreak => 'استراحة طويلة',
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final running = _sw.isRunning;
    final color = _phase == PomoPhase.work ? cs.primary : cs.tertiary;
    final total = _phaseTotal.inMilliseconds;
    final filled = _phase == PomoPhase.longBreak ? 4 : _done % 4;
    return Scaffold(
      appBar: AppBar(title: const Text('بومودورو')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '25', label: Text('25 / 5')),
                ButtonSegment(value: '50', label: Text('50 / 10')),
                ButtonSegment(value: '15', label: Text('15 / 3')),
              ],
              selected: {_preset},
              onSelectionChanged: (s) => _setPreset(s.first),
            ),
          ),
          const SizedBox(height: 20),
          DisplayCard(
            child: Column(children: [
              Text(_label,
                  style: t.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 16),
              TimeRing(
                value: total == 0 ? 0 : _left.inMilliseconds / total,
                color: color,
                child: Text(
                  fmtClock(_left),
                  style: t.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < filled ? color : color.withValues(alpha: 0.2),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              Text('الجلسات المكتملة: $_done',
                  style: t.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: OutlinedButton(onPressed: _reset, child: const Text('إعادة'))),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: running ? _pause : _run,
                child: Text(running ? 'إيقاف مؤقت' : 'ابدأ'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: OutlinedButton(
                    onPressed: () => _next(count: false),
                    child: const Text('تخطي'))),
          ]),
          const SizedBox(height: 20),
          Text('كل 4 جلسات تركيز تأتي استراحة طويلة. الجلسة تُحسب فقط إذا اكتمل وقتها.',
              style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
