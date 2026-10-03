import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/display_card.dart';
import 'time_logic.dart';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});
  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final _sw = Stopwatch();
  Timer? _tick;
  final List<Duration> _laps = [];

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_sw.isRunning) {
      _sw.stop();
      _tick?.cancel();
    } else {
      _sw.start();
      _tick = Timer.periodic(const Duration(milliseconds: 40), (_) {
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }

  void _lap() {
    if (_sw.isRunning) setState(() => _laps.insert(0, _sw.elapsed));
  }

  void _reset() {
    _sw.stop();
    _sw.reset();
    _tick?.cancel();
    setState(() => _laps.clear());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final running = _sw.isRunning;
    final started = _sw.elapsed > Duration.zero;
    return Scaffold(
      appBar: AppBar(title: const Text('ساعة إيقاف')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DisplayCard(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            child: Center(
              child: FittedBox(
                child: Text(
                  fmtStopwatch(_sw.elapsed),
                  style: t.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: started ? _reset : null, child: const Text('إعادة')),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _toggle,
                child: Text(running ? 'إيقاف' : (started ? 'متابعة' : 'ابدأ')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                  onPressed: running ? _lap : null, child: const Text('دورة')),
            ),
          ]),
          if (_laps.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('الدورات',
                style: t.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (var i = 0; i < _laps.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  SizedBox(width: 64, child: Text('#${_laps.length - i}')),
                  Expanded(
                    child: Text(
                      fmtStopwatch(_laps[i] -
                          (i + 1 < _laps.length ? _laps[i + 1] : Duration.zero)),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(fmtStopwatch(_laps[i]),
                      style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                ]),
              ),
              const Divider(),
            ],
          ],
        ],
      ),
    );
  }
}
