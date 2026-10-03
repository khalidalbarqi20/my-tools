import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

Future<Color?> pickColor(BuildContext context,
    {required Color initial, required String title}) {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ColorSheet(initial: initial, title: title),
  );
}

class _ColorSheet extends StatefulWidget {
  final Color initial;
  final String title;
  const _ColorSheet({required this.initial, required this.title});
  @override
  State<_ColorSheet> createState() => _ColorSheetState();
}

class _ColorSheetState extends State<_ColorSheet> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final TextEditingController _hex =
      TextEditingController(text: hexOf(widget.initial));

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(HSVColor h) {
    setState(() {
      _hsv = h;
      _hex.text = hexOf(h.toColor());
    });
  }

  void _fromHex(String s) {
    final c = parseHex(s);
    if (c != null) setState(() => _hsv = HSVColor.fromColor(c));
  }

  Widget _slider(String label, double v, double min, double max,
      ValueChanged<double> onChanged) {
    final value = v < min ? min : (v > max ? max : v);
    return Row(children: [
      SizedBox(width: 64, child: Text(label)),
      Expanded(
        child: Slider(value: value, min: min, max: max, onChanged: onChanged),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final color = _hsv.toColor();
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: t.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.colorScheme.outlineVariant),
              ),
              child: Text('#${hexOf(color)}',
                  style: TextStyle(
                      color: onColor, fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            const SizedBox(height: 8),
            _slider('الدرجة', _hsv.hue, 0, 360, (v) => _set(_hsv.withHue(v))),
            _slider('التشبع', _hsv.saturation, 0, 1,
                (v) => _set(_hsv.withSaturation(v))),
            _slider('السطوع', _hsv.value, 0, 1, (v) => _set(_hsv.withValue(v))),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _hex,
                maxLength: 6,
                onChanged: _fromHex,
                decoration: const InputDecoration(
                    prefixText: '#', labelText: 'كود اللون HEX', counterText: ''),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                    onPressed: () => Navigator.pop(context, color),
                    child: const Text('تطبيق')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
