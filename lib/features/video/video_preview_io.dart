import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_logic.dart' show fmtClock, fmtClockMs;

const _errMsg = 'تعذرت المعاينة على هذا الجهاز. يمكنك حفظ الملف وفتحه في مشغّل آخر.';

Widget _screen(VideoPlayerController c, bool video, BuildContext context) {
  if (!video) {
    return Icon(Icons.audiotrack, size: 64, color: Theme.of(context).colorScheme.primary);
  }
  final ar = c.value.aspectRatio;
  return ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 320),
    child: AspectRatio(aspectRatio: ar > 0 ? ar : 16 / 9, child: VideoPlayer(c)),
  );
}

/// معاينة ناتج العملية: فيديو أو صوت (أو GIF) مع تشغيل وتحريك الشريط.
class MediaPreview extends StatefulWidget {
  final String path;
  final bool video, gif;
  const MediaPreview({super.key, required this.path, required this.video, this.gif = false});
  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  VideoPlayerController? _c;
  bool _err = false;

  @override
  void initState() {
    super.initState();
    if (!widget.gif) _init();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    final c = VideoPlayerController.file(File(widget.path));
    _c = c;
    try {
      await c.initialize();
      c.addListener(_tick);
    } catch (_) {
      if (mounted) setState(() => _err = true);
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c?.removeListener(_tick);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gif) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: Image.file(File(widget.path),
            fit: BoxFit.contain, errorBuilder: (c, e, s) => const Text(_errMsg)),
      );
    }
    final c = _c;
    if (_err || (c != null && c.value.hasError)) return const Text(_errMsg);
    if (c == null || !c.value.isInitialized) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    }
    final dur = c.value.duration.inMilliseconds.toDouble();
    final pos = c.value.position.inMilliseconds.toDouble().clamp(0.0, dur > 0 ? dur : 1.0).toDouble();
    return Column(children: [
      _screen(c, widget.video, context),
      Row(children: [
        IconButton(
          icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () async {
            if (c.value.isPlaying) {
              await c.pause();
            } else {
              if (pos >= dur - 50) await c.seekTo(Duration.zero);
              await c.play();
            }
          },
        ),
        Expanded(
          child: Slider(
            value: pos,
            max: dur > 0 ? dur : 1,
            onChanged: (x) => c.seekTo(Duration(milliseconds: x.round())),
          ),
        ),
        Text(fmtClock(pos / 1000)),
      ]),
    ]);
  }
}

/// معاينة الملف الأصلي مع شريط ببداية ونهاية متحركتين لتحديد مكان القص.
class TrimPicker extends StatefulWidget {
  final String path;
  final bool video;
  final void Function(double start, double? end) onChanged;
  const TrimPicker({super.key, required this.path, required this.video, required this.onChanged});
  @override
  State<TrimPicker> createState() => _TrimPickerState();
}

class _TrimPickerState extends State<TrimPicker> {
  VideoPlayerController? _c;
  bool _err = false, _selPlay = false;
  double _dur = 0, _s = 0, _e = 0, _pos = 0;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// تحديث موضع الخط المتحرك بشكل أنعم من تحديثات المشغّل (كل ~0.5 ثانية).
  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(milliseconds: 60), (_) async {
      final c = _c;
      if (c == null || !mounted || !c.value.isInitialized) return;
      if (!c.value.isPlaying) return;
      final p = await c.position;
      if (p == null || !mounted) return;
      final sec = p.inMilliseconds / 1000;
      if (_selPlay && sec >= _e) {
        _selPlay = false;
        await c.pause();
        await c.seekTo(_ms(_s));
        if (mounted) setState(() => _pos = _s);
        return;
      }
      setState(() => _pos = sec);
    });
  }

  Future<void> _init() async {
    final c = VideoPlayerController.file(File(widget.path));
    _c = c;
    try {
      await c.initialize();
      c.addListener(_tick);
    } catch (_) {
      if (mounted) setState(() => _err = true);
      return;
    }
    if (!mounted) return;
    setState(() {
      _dur = c.value.duration.inMilliseconds / 1000;
      _s = 0;
      _e = _dur;
      _pos = 0;
    });
    _startPoll();
    _emit();
  }

  void _tick() {
    final c = _c;
    if (c == null || !mounted) return;
    if (_selPlay && c.value.position.inMilliseconds / 1000 >= _e) {
      _selPlay = false;
      c.pause();
      c.seekTo(_ms(_s));
    }
    if (!c.value.isPlaying) _pos = c.value.position.inMilliseconds / 1000;
    setState(() {});
  }

  Duration _ms(double sec) => Duration(milliseconds: (sec * 1000).round());

  void _emit() => widget.onChanged(_s, _e >= _dur - 0.05 ? null : _e);

  Future<void> _setStart(double t) async {
    _selPlay = false;
    final c = _c;
    setState(() => _s = t.clamp(0.0, _e - 0.1).toDouble());
    await c?.pause();
    await c?.seekTo(_ms(_s));
    if (mounted) setState(() => _pos = _s);
    _emit();
  }

  Future<void> _setEnd(double t) async {
    _selPlay = false;
    final c = _c;
    setState(() => _e = t.clamp(_s + 0.1, _dur).toDouble());
    await c?.pause();
    await c?.seekTo(_ms(_e));
    if (mounted) setState(() => _pos = _e);
    _emit();
  }

  Future<void> _playSel() async {
    final c = _c;
    if (c == null) return;
    if (c.value.isPlaying) {
      _selPlay = false;
      await c.pause();
      return;
    }
    _selPlay = true;
    await c.seekTo(_ms(_s));
    await c.play();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _c?.removeListener(_tick);
    _c?.dispose();
    super.dispose();
  }

  Widget _nudges(void Function(double d) f) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        children: [
          for (final d in const [-1.0, -0.1, 0.1, 1.0])
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(52, 34), padding: const EdgeInsets.symmetric(horizontal: 6)),
              onPressed: () => f(d),
              child: Text(d > 0 ? '+${d.abs()}' : '-${d.abs()}'),
            ),
        ],
      );

  static const double _pad = 12; // نصف عرض مقبض/هالة السلايدر

  /// بار القص (بداية/نهاية) وفوقه خط عمودي يتحرك مع تشغيل المقطع.
  Widget _barWithPlayhead(ThemeData t) {
    final frac = (_pos / _dur).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      height: 48,
      child: LayoutBuilder(builder: (context, box) {
        final trackW = (box.maxWidth - _pad * 2).clamp(1.0, double.infinity).toDouble();
        return Stack(alignment: Alignment.center, children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              overlayShape: const RoundSliderOverlayShape(overlayRadius: _pad),
              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: RangeSlider(
              values: RangeValues(_s.clamp(0.0, _dur).toDouble(), _e.clamp(0.0, _dur).toDouble()),
              min: 0,
              max: _dur,
              onChanged: (v) {
                if (v.start != _s) {
                  _setStart(v.start);
                } else if (v.end != _e) {
                  _setEnd(v.end);
                }
              },
            ),
          ),
          // PositionedDirectional يحترم اتجاه RTL مثل السلايدر
          PositionedDirectional(
            start: _pad + frac * trackW - 1.5,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Column(children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: t.colorScheme.error, shape: BoxShape.circle),
                ),
                Expanded(child: Container(width: 3, color: t.colorScheme.error)),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (_err || (c != null && c.value.hasError)) return const Text(_errMsg);
    if (c == null || !c.value.isInitialized || _dur <= 0) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    }
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: _screen(c, widget.video, context)),
      _barWithPlayhead(t),
      Center(
        child: Text('الموضع الحالي: ${fmtClockMs(_pos)}',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.primary)),
      ),
      Text('البداية: ${fmtClockMs(_s)}', textAlign: TextAlign.center, style: t.textTheme.titleSmall),
      _nudges((d) => _setStart(_s + d)),
      const SizedBox(height: 8),
      Text('النهاية: ${fmtClockMs(_e)}', textAlign: TextAlign.center, style: t.textTheme.titleSmall),
      _nudges((d) => _setEnd(_e + d)),
      const SizedBox(height: 8),
      Text('مدة المقطع: ${fmtClockMs(_e - _s)}',
          textAlign: TextAlign.center,
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      FilledButton.tonalIcon(
        onPressed: _playSel,
        icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
        label: Text(c.value.isPlaying ? 'إيقاف مؤقت' : 'تشغيل المقطع المحدد'),
      ),
    ]);
  }
}
