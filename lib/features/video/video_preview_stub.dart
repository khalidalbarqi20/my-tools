import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'video_engine.dart' show probeMedia;
import 'video_logic.dart';

// على الويب: مشغّل المتصفح نفسه (video/audio/img) داخل الصفحة عبر HtmlElementView.

extension type _Media._(JSObject _) implements JSObject {
  external JSObject makePlayer(JSString path, JSString kind);
  external void releasePlayer(JSObject el);
}

extension type _Player._(JSObject _) implements JSObject {
  external JSNumber get currentTime;
  external set currentTime(JSNumber v);
  external JSNumber get duration;
  external JSAny? play();
  external void pause();
}

_Media get _m => _Media._(globalContext['mtMedia'] as JSObject);

int _vn = 0;

class _WebPlayer extends StatefulWidget {
  final String path, kind; // kind: video | audio | image
  final double height;
  final void Function(_Player p)? onReady;
  const _WebPlayer({required this.path, required this.kind, required this.height, this.onReady});
  @override
  State<_WebPlayer> createState() => _WebPlayerState();
}

class _WebPlayerState extends State<_WebPlayer> {
  late final String _type = 'mt-player-${_vn++}';
  late final JSObject _el = _m.makePlayer(widget.path.toJS, widget.kind.toJS);

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_type, (int viewId) => _el);
    widget.onReady?.call(_Player._(_el));
  }

  @override
  void dispose() {
    try {
      _m.releasePlayer(_el);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: widget.height, child: HtmlElementView(viewType: _type));
}

/// معاينة نتيجة العملية داخل الصفحة (فيديو/صوت/GIF) قبل الحفظ.
class MediaPreview extends StatelessWidget {
  final String path;
  final bool video, gif;
  const MediaPreview({super.key, required this.path, required this.video, this.gif = false});
  @override
  Widget build(BuildContext context) {
    final kind = gif ? 'image' : (video ? 'video' : 'audio');
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _WebPlayer(path: path, kind: kind, height: kind == 'audio' ? 56 : 240),
    );
  }
}

/// قص بالمعاينة: الفيديو يظهر، تحرّك شريط البداية/النهاية وتشاهد اللقطة، وتجرّب المقطع قبل القص.
class TrimPicker extends StatefulWidget {
  final String path;
  final bool video;
  final void Function(double start, double? end) onChanged;
  const TrimPicker({super.key, required this.path, required this.video, required this.onChanged});
  @override
  State<TrimPicker> createState() => _TrimPickerState();
}

class _TrimPickerState extends State<TrimPicker> {
  final _sc = TextEditingController(text: '0');
  final _ec = TextEditingController();
  _Player? _p;
  Timer? _timer;
  double? _dur;
  double _s = 0;
  double? _e; // null = للآخر
  double _cur = 0;
  bool _range = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    probeMedia(widget.path).then((i) {
      final d = i.duration;
      if (mounted && d != null && d > 0) setState(() => _dur = d);
    }, onError: (_) {});
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _p?.pause();
    _sc.dispose();
    _ec.dispose();
    super.dispose();
  }

  void _tick() {
    final p = _p;
    if (p == null || !mounted) return;
    final c = p.currentTime.toDartDouble;
    var changed = (c - _cur).abs() > 0.05;
    if (_dur == null) {
      final d = p.duration.toDartDouble;
      if (d.isFinite && d > 0) {
        _dur = d;
        changed = true;
      }
    }
    if (_range) {
      final end = _e ?? _dur ?? double.infinity;
      if (c >= end - 0.05) {
        p.pause();
        _range = false;
        changed = true;
      }
    }
    if (changed) setState(() => _cur = c);
  }

  void _seek(double t) {
    _p?.currentTime = t.toJS;
  }

  void _emit() {
    final d = _dur;
    var e = _e;
    if (e != null && d != null && e >= d - 0.05) e = null;
    widget.onChanged(_s, e);
  }

  void _syncFields() {
    final d = _dur ?? 0;
    _sc.text = fmtClock(_s);
    final e = _e;
    _ec.text = (e == null || e >= d - 0.05) ? '' : fmtClock(e);
  }

  void _onSlider(RangeValues v) {
    final movedStart = (v.start - _s).abs() > 1e-6;
    _p?.pause();
    setState(() {
      _s = v.start;
      _e = v.end;
      _err = null;
      _range = false;
    });
    _seek(movedStart ? v.start : v.end);
    _syncFields();
    _emit();
  }

  void _typed() {
    final st = _sc.text.trim().isEmpty ? 0.0 : parseClock(_sc.text);
    final et = _ec.text.trim();
    final en = et.isEmpty ? null : parseClock(et);
    String? err;
    if (st == null) {
      err = 'وقت البداية غير صالح';
    } else if (et.isNotEmpty && en == null) {
      err = 'وقت النهاية غير صالح';
    } else if (en != null && en <= st) {
      err = 'النهاية لازم تكون بعد البداية';
    } else if (_dur != null && st >= _dur!) {
      err = 'البداية بعد نهاية الفيديو';
    }
    setState(() => _err = err);
    if (err == null && st != null) {
      setState(() {
        _s = st;
        _e = en;
      });
      _seek(st);
      _emit();
    }
  }

  void _markStart() {
    final c = _p?.currentTime.toDartDouble ?? _cur;
    final e = _e ?? _dur;
    if (e != null && c >= e - 0.05) {
      setState(() => _err = 'البداية لازم تكون قبل النهاية');
      return;
    }
    setState(() {
      _s = c;
      _err = null;
    });
    _syncFields();
    _emit();
  }

  void _markEnd() {
    final c = _p?.currentTime.toDartDouble ?? _cur;
    if (c <= _s + 0.05) {
      setState(() => _err = 'النهاية لازم تكون بعد البداية');
      return;
    }
    setState(() {
      _e = c;
      _err = null;
    });
    _syncFields();
    _emit();
  }

  void _playRange() {
    final p = _p;
    if (p == null) return;
    _seek(_s);
    _range = true;
    p.play();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final d = _dur;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _WebPlayer(
          path: widget.path,
          kind: widget.video ? 'video' : 'audio',
          height: widget.video ? 240 : 56,
          onReady: (p) => _p = p,
        ),
        const SizedBox(height: 8),
        if (d != null) ...[
          Center(
              child: Text('${fmtClock(_cur)} / ${fmtClock(d)}',
                  style: t.textTheme.bodySmall
                      ?.copyWith(color: t.colorScheme.onSurfaceVariant))),
          RangeSlider(
            min: 0,
            max: d,
            values: RangeValues(
                _s.clamp(0.0, d).toDouble(), (_e ?? d).clamp(0.0, d).toDouble()),
            onChanged: _onSlider,
          ),
        ],
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton(onPressed: _markStart, child: const Text('البداية = الآن')),
          OutlinedButton(onPressed: _markEnd, child: const Text('النهاية = الآن')),
          FilledButton.tonalIcon(
              onPressed: _playRange,
              icon: const Icon(Icons.play_arrow),
              label: const Text('جرّب المقطع')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _sc,
              keyboardType: TextInputType.datetime,
              onChanged: (_) => _typed(),
              decoration: const InputDecoration(labelText: 'البداية (مثال 0:30)'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _ec,
              keyboardType: TextInputType.datetime,
              onChanged: (_) => _typed(),
              decoration: const InputDecoration(labelText: 'النهاية (فارغ = للآخر)'),
            ),
          ),
        ]),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
          ),
      ]),
    );
  }
}
