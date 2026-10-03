import 'package:flutter/material.dart';
import '../pdf/pdf_common.dart' show OutFile, ResultList, baseName;
import 'image_common.dart';
import 'image_ops.dart';

class RotatePage extends StatefulWidget {
  const RotatePage({super.key});
  @override
  State<RotatePage> createState() => _RotatePageState();
}

class _RotatePageState extends State<RotatePage> {
  LoadedImage? _img;
  int _turns = 0;
  bool _fh = false, _fv = false;
  String _fmt = 'jpg';
  bool _busy = false;
  String? _err;
  List<OutFile> _out = [];

  bool get _changed => _turns != 0 || _fh || _fv;

  Future<void> _pick() async {
    try {
      final x = await pickOneImage();
      if (x == null || !mounted) return;
      setState(() {
        _img = x;
        _reset();
        _err = null;
      });
    } catch (e) {
      if (mounted) setState(() => _err = imgError(e));
    }
  }

  void _reset() {
    _turns = 0;
    _fh = false;
    _fv = false;
    _out = [];
  }

  // القلب يخص الصورة كما تظهر: مع تدوير 90/270 يتبدل المحور داخليًا.
  void _flipHorizontal() => setState(() {
        if (_turns.isOdd) {
          _fv = !_fv;
        } else {
          _fh = !_fh;
        }
        _out = [];
      });

  void _flipVertical() => setState(() {
        if (_turns.isOdd) {
          _fh = !_fh;
        } else {
          _fv = !_fv;
        }
        _out = [];
      });

  Future<void> _run() async {
    final x = _img;
    if (x == null) return;
    setState(() {
      _busy = true;
      _err = null;
      _out = [];
    });
    try {
      final f = fmtFromKey(_fmt);
      final data =
          await transformEncode(x.file.bytes, _turns, _fh, _fv, f, 90);
      final o = OutFile(
          '${baseName(x.file.name)}_edit.${extOf(f)}', data, mimeOf(f));
      if (mounted) setState(() => _out = [o]);
    } catch (e) {
      if (mounted) setState(() => _err = imgError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final x = _img;
    return Scaffold(
      appBar: AppBar(title: const Text('تدوير وقلب الصورة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(x == null ? 'اختيار صورة' : 'تغيير الصورة'),
          ),
          if (x != null) ...[
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: RotatedBox(
                  quarterTurns: _turns,
                  child: Transform.flip(
                    flipX: _fh,
                    flipY: _fv,
                    child: Image.memory(x.file.bytes, cacheWidth: 1000),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                  onPressed: () => setState(() {
                        _turns = (_turns + 3) % 4;
                        _out = [];
                      }),
                  icon: const Icon(Icons.rotate_left),
                  label: const Text('يسار')),
              OutlinedButton.icon(
                  onPressed: () => setState(() {
                        _turns = (_turns + 1) % 4;
                        _out = [];
                      }),
                  icon: const Icon(Icons.rotate_right),
                  label: const Text('يمين')),
              OutlinedButton.icon(
                  onPressed: _flipHorizontal,
                  icon: const Icon(Icons.flip),
                  label: const Text('قلب أفقي')),
              OutlinedButton.icon(
                  onPressed: _flipVertical,
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('قلب رأسي')),
              TextButton.icon(
                  onPressed: () => setState(_reset),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('إعادة')),
            ]),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                for (final k in ['jpg', 'png', 'webp'])
                  ButtonSegment(value: k, label: Text(k.toUpperCase()))
              ],
              selected: {_fmt},
              onSelectionChanged: (s) => setState(() => _fmt = s.first),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: (_busy || !_changed) ? null : _run,
              child: const Text('حفظ التعديل'),
            ),
          ],
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator()),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
            ),
          ResultList(_out),
        ],
      ),
    );
  }
}
