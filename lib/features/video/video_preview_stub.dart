import 'package:flutter/material.dart';
import 'video_logic.dart';

/// على الويب المعاينة تتم بزر «معاينة» (تفتح الملف في تبويب)، فلا نعرض مشغّلًا هنا.
class MediaPreview extends StatelessWidget {
  final String path;
  final bool video, gif;
  const MediaPreview({super.key, required this.path, required this.video, this.gif = false});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// على الويب: حقلا بداية ونهاية بدل الشريط المتحرك (صيغة 1:30 أو 90 أو 1:02:03).
class TrimPicker extends StatefulWidget {
  final String path;
  final bool video;
  final void Function(double start, double? end) onChanged;
  const TrimPicker({super.key, required this.path, required this.video, required this.onChanged});
  @override
  State<TrimPicker> createState() => _TrimPickerState();
}

class _TrimPickerState extends State<TrimPicker> {
  final _s = TextEditingController(text: '0');
  final _e = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _s.dispose();
    _e.dispose();
    super.dispose();
  }

  void _changed() {
    final s = _s.text.trim().isEmpty ? 0.0 : parseClock(_s.text);
    final eTxt = _e.text.trim();
    final e = eTxt.isEmpty ? null : parseClock(eTxt);
    String? err;
    if (s == null) {
      err = 'وقت البداية غير صالح';
    } else if (eTxt.isNotEmpty && e == null) {
      err = 'وقت النهاية غير صالح';
    } else if (e != null && e <= s) {
      err = 'النهاية لازم تكون بعد البداية';
    }
    setState(() => _err = err);
    if (err == null && s != null) widget.onChanged(s, e);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _s,
              keyboardType: TextInputType.datetime,
              onChanged: (_) => _changed(),
              decoration: const InputDecoration(labelText: 'البداية (مثال 0:30)'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _e,
              keyboardType: TextInputType.datetime,
              onChanged: (_) => _changed(),
              decoration: const InputDecoration(labelText: 'النهاية (فارغ = للآخر)'),
            ),
          ),
        ]),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ]),
    );
  }
}
