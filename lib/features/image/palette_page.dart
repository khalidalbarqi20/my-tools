import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'image_common.dart';
import 'image_logic.dart';
import 'image_ops.dart';

class PalettePage extends StatefulWidget {
  const PalettePage({super.key});
  @override
  State<PalettePage> createState() => _PalettePageState();
}

class _PalettePageState extends State<PalettePage> {
  LoadedImage? _img;
  List<PaletteColor> _cols = [];
  bool _busy = false;
  String? _err;

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final x = await pickOneImage();
      if (x == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final c = await paletteOf(x.file.bytes);
      if (!mounted) return;
      setState(() {
        _img = x;
        _cols = c;
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _err = imgError(e);
          _busy = false;
        });
      }
    }
  }

  void _copy(String s) {
    Clipboard.setData(ClipboardData(text: s));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('تم نسخ $s')));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final x = _img;
    return Scaffold(
      appBar: AppBar(title: const Text('استخراج الألوان')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(x == null ? 'اختيار صورة' : 'تغيير الصورة'),
          ),
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator()),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
            ),
          if (x != null) ...[
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(x.file.bytes, cacheWidth: 800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_cols.isEmpty) const Text('ما قدرنا نستخرج ألوان من هذي الصورة'),
            for (final c in _cols)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(0xFF000000 | (c.r << 16) | (c.g << 8) | c.b),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.colorScheme.outlineVariant),
                  ),
                ),
                title: Text(c.hex),
                subtitle: Text(
                    'RGB(${c.r}, ${c.g}, ${c.b}) • ${(c.share * 100).toStringAsFixed(0)}%'),
                trailing: const Icon(Icons.copy),
                onTap: () => _copy(c.hex),
              ),
            if (_cols.isNotEmpty)
              OutlinedButton(
                onPressed: () => _copy(_cols.map((c) => c.hex).join(', ')),
                child: const Text('نسخ كل الألوان'),
              ),
          ],
        ],
      ),
    );
  }
}
