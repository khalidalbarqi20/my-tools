import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';
import 'device_logic.dart';

Widget _note(BuildContext c, String t) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(t,
          style: Theme.of(c)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(c).colorScheme.onSurfaceVariant)),
    );

Widget _status(BuildContext c, IconData icon, String t, {bool bad = false}) {
  final cs = Theme.of(c).colorScheme;
  final col = bad ? cs.error : cs.primary;
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: col.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Icon(icon, color: col),
      const SizedBox(width: 10),
      Expanded(child: Text(t)),
    ]),
  );
}

// ───────────────────────── اختبار الاهتزاز (محرك الاهتزاز الفعلي) ─────────────────────────
class VibrationTestPage extends StatefulWidget {
  const VibrationTestPage({super.key});
  @override
  State<VibrationTestPage> createState() => _VibrationTestPageState();
}

class _VibrationTestPageState extends State<VibrationTestPage> {
  bool? _has;
  bool _amp = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    Vibration.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    var has = false, amp = false;
    try {
      has = (await Vibration.hasVibrator()) == true;
      amp = has && (await Vibration.hasAmplitudeControl()) == true;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _has = has;
      _amp = amp;
    });
  }

  Future<void> _go({int ms = 300, List<int>? pattern, int amplitude = -1}) async {
    try {
      await Vibration.cancel();
      if (pattern != null) {
        await Vibration.vibrate(pattern: pattern);
      } else {
        await Vibration.vibrate(duration: ms, amplitude: _amp ? amplitude : -1);
      }
      if (mounted) setState(() => _err = null);
    } catch (_) {
      if (mounted) setState(() => _err = 'تعذر تشغيل الاهتزاز على هذا الجهاز');
    }
  }

  @override
  Widget build(BuildContext context) {
    final has = _has;
    Widget btn(String label, VoidCallback f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton.tonalIcon(
            onPressed: has == true ? f : null,
            icon: const Icon(Icons.vibration),
            label: Text(label),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار الاهتزاز')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (has == null)
          const Center(child: CircularProgressIndicator())
        else if (!has)
          _status(context, Icons.vibration, 'هذا الجهاز لا يحتوي على محرك اهتزاز (أو النظام لا يسمح للتطبيق باستخدامه).', bad: true)
        else
          _status(context, Icons.check_circle_outline,
              _amp ? 'محرك الاهتزاز متوفر ويدعم تغيير القوة' : 'محرك الاهتزاز متوفر (بقوة ثابتة)'),
        const SizedBox(height: 16),
        btn('اهتزاز قصير (0.1 ثانية)', () => _go(ms: 100)),
        btn('اهتزاز متوسط (0.5 ثانية)', () => _go(ms: 500)),
        btn('اهتزاز طويل (1.5 ثانية)', () => _go(ms: 1500)),
        if (_amp) btn('اهتزاز خفيف', () => _go(ms: 400, amplitude: 60)),
        if (_amp) btn('اهتزاز قوي', () => _go(ms: 400, amplitude: 255)),
        btn('نمط متقطع', () => _go(pattern: [0, 200, 150, 200, 150, 500])),
        OutlinedButton.icon(
          onPressed: has == true ? Vibration.cancel : null,
          icon: const Icon(Icons.stop),
          label: const Text('إيقاف'),
        ),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        _note(context,
            'إذا ظهر أن المحرك متوفر ولم تشعر باهتزاز: تأكد أن الهاتف ليس في وضع الصامت أو توفير الطاقة، '
            'وأن إعداد «الاهتزاز» مفعّل لتطبيقات الطرف الثالث في إعدادات النظام (بعض الأجهزة تمنعه).'),
      ]),
    );
  }
}

// ───────────────────────── اختبار الكاميرا ─────────────────────────
class CameraTestPage extends StatefulWidget {
  const CameraTestPage({super.key});
  @override
  State<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> {
  final MobileScannerController _c = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار الكاميرا'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _c,
            builder: (context, s, child) {
              final na = s.torchState == TorchState.unavailable;
              return IconButton(
                tooltip: na ? 'الفلاش غير متوفر' : 'الفلاش',
                icon: Icon(s.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off),
                onPressed: na ? null : () => _c.toggleTorch(),
              );
            },
          ),
          IconButton(
            tooltip: 'تبديل الكاميرا',
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _c.switchCamera(),
          ),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        MobileScanner(controller: _c),
        ValueListenableBuilder<MobileScannerState>(
          valueListenable: _c,
          builder: (context, s, child) {
            final cams = s.availableCameras;
            if (s.error != null) {
              return Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'تعذر تشغيل الكاميرا: إما أن الإذن مرفوض (فعّله من إعدادات التطبيق) أو أن الجهاز لا يملك كاميرا.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: () => _c.start(), child: const Text('إعادة المحاولة')),
                ]),
              );
            }
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                color: Colors.black54,
                padding: const EdgeInsets.all(12),
                child: Text(
                  [
                    if (cams != null) 'عدد الكاميرات: $cams',
                    s.cameraDirection == CameraFacing.front ? 'الأمامية' : 'الخلفية',
                    s.torchState == TorchState.unavailable ? 'الفلاش غير متوفر في هذه الكاميرا' : 'الفلاش متوفر',
                  ].join('  •  '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ───────────────────────── اختبار الميكروفون ─────────────────────────
class MicTestPage extends StatefulWidget {
  const MicTestPage({super.key});
  @override
  State<MicTestPage> createState() => _MicTestPageState();
}

class _MicTestPageState extends State<MicTestPage> {
  final AudioRecorder _rec = AudioRecorder();
  StreamSubscription<Amplitude>? _amp;
  StreamSubscription<Uint8List>? _data;
  bool _on = false;
  double _level = 0, _peak = 0;
  String? _err;

  Future<void> _start() async {
    try {
      if (!await _rec.hasPermission()) {
        setState(() => _err = 'إذن الميكروفون مرفوض. فعّله من إعدادات التطبيق ثم أعد المحاولة.');
        return;
      }
      final st = await _rec.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));
      _data = st.listen((_) {});
      _amp = _rec.onAmplitudeChanged(const Duration(milliseconds: 80)).listen((a) {
        if (!mounted) return;
        final l = micLevel(a.current);
        setState(() {
          _level = l;
          if (l > _peak) _peak = l;
        });
      });
      setState(() {
        _on = true;
        _err = null;
        _peak = 0;
      });
    } catch (_) {
      await _stop();
      if (mounted) setState(() => _err = 'تعذر تشغيل الميكروفون على هذا الجهاز');
    }
  }

  Future<void> _stop() async {
    await _amp?.cancel();
    await _data?.cancel();
    _amp = null;
    _data = null;
    try {
      await _rec.stop();
    } catch (_) {}
    if (mounted) setState(() {
      _on = false;
      _level = 0;
    });
  }

  @override
  void dispose() {
    _amp?.cancel();
    _data?.cancel();
    _rec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار الميكروفون')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Icon(_on ? Icons.mic : Icons.mic_none, size: 72, color: _on ? cs.primary : cs.onSurfaceVariant),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: _level, minHeight: 18),
        ),
        const SizedBox(height: 8),
        Text(_on ? 'تحدث الآن... أعلى مستوى: ${(_peak * 100).round()}%' : 'اضغط «ابدأ» ثم تحدث أو صفّق',
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _on ? _stop : _start,
          icon: Icon(_on ? Icons.stop : Icons.mic),
          label: Text(_on ? 'إيقاف' : 'ابدأ الاختبار'),
        ),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_err!, style: TextStyle(color: cs.error)),
          ),
        _note(context,
            'إذا تحرك المؤشر عند الكلام فالميكروفون سليم. لا يتم حفظ أو إرسال أي صوت؛ يُقاس المستوى فقط أثناء الاختبار.'),
      ]),
    );
  }
}

// ───────────────────────── اختبار السماعة ─────────────────────────
class SpeakerTestPage extends StatefulWidget {
  const SpeakerTestPage({super.key});
  @override
  State<SpeakerTestPage> createState() => _SpeakerTestPageState();
}

class _SpeakerTestPageState extends State<SpeakerTestPage> {
  final AudioPlayer _p = AudioPlayer();
  String? _err;
  double _freq = 440;

  Future<void> _play({bool l = true, bool r = true}) async {
    try {
      await _p.stop();
      final wav = toneWav(freq: _freq, left: l, right: r);
      await _p.play(BytesSource(Uint8List.fromList(wav), mimeType: 'audio/wav'));
      if (mounted) setState(() => _err = null);
    } catch (_) {
      if (mounted) setState(() => _err = 'تعذر تشغيل الصوت على هذا الجهاز');
    }
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, IconData icon, VoidCallback f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton.tonalIcon(onPressed: f, icon: Icon(icon), label: Text(label)),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار السماعة')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        btn('تشغيل نغمة (الاثنتان)', Icons.volume_up, () => _play()),
        btn('السماعة اليسرى فقط', Icons.chevron_left, () => _play(r: false)),
        btn('السماعة اليمنى فقط', Icons.chevron_right, () => _play(l: false)),
        const SizedBox(height: 8),
        Text('التردد: ${_freq.round()} هرتز'),
        Slider(
          value: _freq,
          min: 100,
          max: 4000,
          onChanged: (v) => setState(() => _freq = v),
        ),
        OutlinedButton.icon(onPressed: _p.stop, icon: const Icon(Icons.stop), label: const Text('إيقاف')),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        _note(context,
            'ارفع صوت الوسائط وتأكد أن الهاتف ليس في وضع الصامت. معظم الهواتف لها سماعة واحدة فقط، فقد تسمع اليمنى واليسرى من نفس المكان؛ '
            'الاختبار مفيد أكثر مع سماعات الأذن.'),
      ]),
    );
  }
}
