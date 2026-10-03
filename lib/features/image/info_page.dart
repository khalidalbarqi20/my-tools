import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pdf/pdf_common.dart' show humanSize;
import 'image_common.dart';
import 'image_logic.dart';

class ImageInfoPage extends StatefulWidget {
  const ImageInfoPage({super.key});
  @override
  State<ImageInfoPage> createState() => _ImageInfoPageState();
}

class _ImageInfoPageState extends State<ImageInfoPage> {
  LoadedImage? _img;
  String? _err;

  Future<void> _pick() async {
    try {
      final x = await pickOneImage();
      if (x == null || !mounted) return;
      setState(() {
        _img = x;
        _err = null;
      });
    } catch (e) {
      if (mounted) setState(() => _err = imgError(e));
    }
  }

  List<(String, String)> _rows(LoadedImage x) => [
        ('الاسم', x.file.name),
        ('الحجم', humanSize(x.file.bytes.length)),
        ('الصيغة', detectFormat(x.file.bytes)),
        ('الأبعاد', '${x.dims.w} × ${x.dims.h} بكسل'),
        ('الدقة', '${(x.dims.w * x.dims.h / 1e6).toStringAsFixed(1)} ميجابكسل'),
        ('النسبة', aspectLabel(x.dims.w, x.dims.h)),
      ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final x = _img;
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات الصورة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(x == null ? 'اختيار صورة' : 'تغيير الصورة'),
          ),
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
            for (final r in _rows(x)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Text(r.$1),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(r.$2,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: _rows(x).map((r) => '${r.$1}: ${r.$2}').join('\n')));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('تم النسخ')));
              },
              child: const Text('نسخ المعلومات'),
            ),
          ],
        ],
      ),
    );
  }
}
