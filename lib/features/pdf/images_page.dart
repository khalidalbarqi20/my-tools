import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'images_to_pdf.dart';
import 'pdf_common.dart';

class ImagesToPdfPage extends StatefulWidget {
  const ImagesToPdfPage({super.key});
  @override
  State<ImagesToPdfPage> createState() => _ImagesToPdfPageState();
}

class _ImagesToPdfPageState extends State<ImagesToPdfPage> {
  final List<Picked> _imgs = [];
  bool _landscape = false;
  bool _busy = false;
  String? _err;
  List<OutFile> _out = [];

  Future<void> _add() async {
    try {
      final f = await pickPicked(type: FileType.image);
      if (f.isEmpty || !mounted) return;
      setState(() {
        _imgs.addAll(f);
        _out = [];
        _err = null;
      });
    } catch (e) {
      if (mounted) setState(() => _err = friendlyError(e));
    }
  }

  Future<void> _make() async {
    setState(() {
      _busy = true;
      _err = null;
      _out = [];
    });
    try {
      final o = await imagesToPdf(_imgs, landscape: _landscape);
      if (mounted) setState(() => _out = [o]);
    } catch (_) {
      if (mounted) {
        setState(() => _err =
            'تعذر قراءة إحدى الصور. استخدم صور JPG أو PNG ثم حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('صور إلى PDF')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _add,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('إضافة صور'),
          ),
          const SizedBox(height: 8),
          if (_imgs.length > 1)
            Text('اسحب ≡ لترتيب الصور (كل صورة في صفحة)',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _imgs.length,
            onReorder: (a, b) => setState(() {
              if (b > a) b--;
              _imgs.insert(b, _imgs.removeAt(a));
            }),
            itemBuilder: (c, i) => ListTile(
              key: ObjectKey(_imgs[i]),
              contentPadding: EdgeInsets.zero,
              leading: ReorderableDragStartListener(
                index: i,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_imgs[i].bytes,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      cacheWidth: 96,
                      errorBuilder: (c, e, s) =>
                          const SizedBox(width: 48, height: 48, child: Icon(Icons.image_not_supported_outlined))),
                ),
              ),
              title: Text(_imgs[i].name, overflow: TextOverflow.ellipsis),
              subtitle: Text(humanSize(_imgs[i].bytes.length)),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _imgs.removeAt(i);
                          _out = [];
                        }),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('صفحات أفقية'),
            value: _landscape,
            onChanged: (v) => setState(() => _landscape = v),
          ),
          FilledButton(
            onPressed: (_imgs.isEmpty || _busy) ? null : _make,
            child: const Text('إنشاء PDF'),
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
          ResultList(_out),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text('كل صورة تُوضع كاملة داخل صفحة A4. الصور الكبيرة جدًا قد تأخذ وقتًا أطول.',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
