import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../image/image_common.dart';
import 'pdf_common.dart';
import 'pdf_ops.dart';

bool isImageOut(OutFile f) => f.mime.startsWith('image/');
bool isPdfOut(OutFile f) => f.mime == 'application/pdf';

const imageExportFormats = [
  ('jpg', 'JPG'),
  ('jpeg', 'JPEG'),
  ('png', 'PNG'),
  ('webp', 'WebP'),
];

String _mimeForKey(String k) =>
    k == 'png' ? 'image/png' : (k == 'webp' ? 'image/webp' : 'image/jpeg');

/// يحوّل صورة ناتجة إلى صيغة أخرى. JPG لا يدعم الشفافية، لذلك تُملأ الخلفية بالأبيض.
Future<OutFile> convertImageOut(OutFile f, String key, int quality) async {
  if (key == 'png' && f.mime == 'image/png') return f;
  final src = await decodeCapped(f.bytes);
  try {
    Uint8List data;
    if (key == 'jpg' || key == 'jpeg') {
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      c.drawRect(
          ui.Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
          ui.Paint()..color = const ui.Color(0xFFFFFFFF));
      c.drawImage(src, ui.Offset.zero, ui.Paint());
      final pic = rec.endRecording();
      final flat = await pic.toImage(src.width, src.height);
      pic.dispose();
      try {
        data = await encodeUi(flat, OutFmt.jpg, quality);
      } finally {
        flat.dispose();
      }
    } else if (key == 'webp') {
      data = await encodeUi(src, OutFmt.webp, quality);
    } else {
      data = await encodeUi(src, OutFmt.png, 100);
    }
    return OutFile('${baseName(f.name)}.$key', data, _mimeForKey(key));
  } finally {
    src.dispose();
  }
}

/// يصدّر صفحات PDF كصور PNG أو JPG.
Future<List<OutFile>> exportPdfAsImages(OutFile f, String key, int dpi) async {
  final n = await countPages(f.bytes, f.name);
  final pngs = await pdfToImages(
      f.bytes, baseName(f.name), n, {'pages': '', 'dpi': '$dpi'});
  if (key == 'png') return pngs;
  return [for (final p in pngs) await convertImageOut(p, 'jpg', 90)];
}

class _Choice {
  final String key;
  final int quality;
  const _Choice(this.key, this.quality);
}

bool _same(List<OutFile> a, List<OutFile> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}

/// قائمة نتائج عامة: معاينة، تصدير بصيغة أخرى، حفظ، ومشاركة.
class ResultList extends StatefulWidget {
  final List<OutFile> files;
  const ResultList(this.files, {super.key});
  @override
  State<ResultList> createState() => _ResultListState();
}

class _ResultListState extends State<ResultList> {
  late List<OutFile> _cur = List.of(widget.files);
  bool _busy = false, _changed = false;

  @override
  void didUpdateWidget(ResultList old) {
    super.didUpdateWidget(old);
    if (!_same(old.files, widget.files)) {
      _cur = List.of(widget.files);
      _changed = false;
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  void _preview(OutFile f) {
    if (isImageOut(f)) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ImagePreviewPage(f)));
    } else if (isPdfOut(f)) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => PdfBytesPreviewPage(f)));
    }
  }

  Future<_Choice?> _askFormat(OutFile f) {
    final pdf = isPdfOut(f);
    final formats = pdf
        ? const [('png', 'صور PNG'), ('jpg', 'صور JPG')]
        : imageExportFormats;
    String? key;
    double q = 90;
    return showModalBottomSheet<_Choice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final lossy = key == 'jpg' || key == 'jpeg' || key == 'webp';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تصدير بصيغة', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in formats)
                    ChoiceChip(
                        label: Text(e.$2),
                        selected: key == e.$1,
                        onSelected: (_) => set(() => key = e.$1)),
                ]),
                if (!pdf && lossy) ...[
                  const SizedBox(height: 12),
                  Text('الجودة: ${q.round()}%'),
                  Slider(
                      value: q,
                      min: 40,
                      max: 100,
                      divisions: 12,
                      onChanged: (v) => set(() => q = v)),
                ],
                if (pdf)
                  const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('تُصدَّر كل صفحة كصورة (حتى 30 صفحة).')),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: key == null
                        ? null
                        : () => Navigator.pop(ctx, _Choice(key!, q.round())),
                    child: const Text('تصدير'),
                  ),
                ),
              ]),
        );
      }),
    );
  }

  Future<void> _export(int i) async {
    final f = _cur[i];
    final sel = await _askFormat(f);
    if (sel == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final List<OutFile> repl = isPdfOut(f)
          ? await exportPdfAsImages(f, sel.key, 150)
          : [await convertImageOut(f, sel.key, sel.quality)];
      if (!mounted) return;
      setState(() {
        _cur.replaceRange(i, i + 1, repl);
        _changed = true;
      });
      _snack('تم التصدير بصيغة ${sel.key.toUpperCase()}');
    } catch (e) {
      _snack(e is FormatException ? e.message : 'تعذر التصدير بهذه الصيغة');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _thumb(OutFile f) {
    if (isImageOut(f)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(f.bytes,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            cacheWidth: 96,
            errorBuilder: (c, e, s) =>
                const SizedBox(width: 48, height: 48, child: Icon(Icons.image_outlined))),
      );
    }
    return const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.picture_as_pdf_outlined, size: 32));
  }

  @override
  Widget build(BuildContext context) {
    if (_cur.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: Text('النتيجة', style: t.textTheme.titleMedium)),
        if (_changed)
          TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _cur = List.of(widget.files);
                        _changed = false;
                      }),
              child: const Text('استرجاع الأصل')),
      ]),
      if (_busy) const LinearProgressIndicator(),
      for (var i = 0; i < _cur.length; i++) _tile(i, _cur[i]),
      if (_cur.length > 1)
        OutlinedButton.icon(
            onPressed: () => shareOut(context, _cur),
            icon: const Icon(Icons.share),
            label: const Text('مشاركة الكل')),
    ]);
  }

  Widget _tile(int i, OutFile f) {
    final canPreview = isImageOut(f) || isPdfOut(f);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _thumb(f),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, overflow: TextOverflow.ellipsis),
                Text(humanSize(f.bytes.length),
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ]),
          Wrap(spacing: 4, children: [
            if (canPreview)
              TextButton.icon(
                  onPressed: () => _preview(f),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('معاينة')),
            if (canPreview)
              TextButton.icon(
                  onPressed: _busy ? null : () => _export(i),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('تصدير بصيغة')),
            TextButton.icon(
                onPressed: () => saveOut(context, f),
                icon: const Icon(Icons.download),
                label: const Text('حفظ')),
            TextButton.icon(
                onPressed: () => shareOut(context, [f]),
                icon: const Icon(Icons.share),
                label: const Text('مشاركة')),
          ]),
        ]),
      ),
    );
  }
}

class _Checker extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const s = 16.0;
    final a = Paint()..color = const Color(0xFF3A3A3A);
    final b = Paint()..color = const Color(0xFF4A4A4A);
    for (var y = 0; y * s < size.height; y++) {
      for (var x = 0; x * s < size.width; x++) {
        canvas.drawRect(Rect.fromLTWH(x * s, y * s, s, s), (x + y).isEven ? a : b);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// معاينة صورة بملء الشاشة مع تكبير وتصغير، وخلفية مربعات لإظهار الشفافية.
class ImagePreviewPage extends StatelessWidget {
  final OutFile file;
  const ImagePreviewPage(this.file, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
              tooltip: 'حفظ',
              icon: const Icon(Icons.download),
              onPressed: () => saveOut(context, file)),
          IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.share),
              onPressed: () => shareOut(context, [file])),
        ],
      ),
      body: CustomPaint(
        painter: _Checker(),
        child: SizedBox.expand(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 8,
            child: Center(
              child: Image.memory(file.bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined, size: 64)),
            ),
          ),
        ),
      ),
    );
  }
}

/// معاينة ملف PDF ناتج من الذاكرة (كل الصفحات).
class PdfBytesPreviewPage extends StatefulWidget {
  final OutFile file;
  const PdfBytesPreviewPage(this.file, {super.key});
  @override
  State<PdfBytesPreviewPage> createState() => _PdfBytesPreviewPageState();
}

class _PdfBytesPreviewPageState extends State<PdfBytesPreviewPage> {
  PdfDocument? _doc;
  String? _err;
  final Map<int, Future<Uint8List?>> _cache = {};

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      ensurePdfInit();
      final d = await PdfDocument.openData(widget.file.bytes,
          sourceName: widget.file.name);
      if (!mounted) {
        await d.dispose();
        return;
      }
      setState(() => _doc = d);
    } catch (e) {
      if (mounted) setState(() => _err = friendlyError(e));
    }
  }

  @override
  void dispose() {
    _doc?.dispose();
    super.dispose();
  }

  Future<Uint8List?> _render(int i, double pxWidth) {
    final c = _cache[i];
    if (c != null) return c;
    if (_cache.length > 12) _cache.remove(_cache.keys.first);
    final p = _doc!.pages[i];
    return _cache[i] = renderPng(p, scale: pxWidth / p.width, maxSide: 2000);
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
              tooltip: 'حفظ',
              icon: const Icon(Icons.download),
              onPressed: () => saveOut(context, widget.file)),
          IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.share),
              onPressed: () => shareOut(context, [widget.file])),
        ],
      ),
      body: _err != null
          ? Center(child: Text(_err!))
          : doc == null
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: doc.pages.length,
                  itemBuilder: (context, i) {
                    final p = doc.pages[i];
                    final w = MediaQuery.sizeOf(context).width;
                    final dpr = MediaQuery.devicePixelRatioOf(context);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: AspectRatio(
                        aspectRatio: p.width / p.height,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                          ),
                          child: FutureBuilder<Uint8List?>(
                            future: _render(i, w * dpr),
                            builder: (c, s) {
                              if (s.hasError ||
                                  (s.connectionState == ConnectionState.done && s.data == null)) {
                                return const Center(
                                    child: Icon(Icons.broken_image_outlined, color: Colors.grey));
                              }
                              if (s.data == null) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              return Image.memory(s.data!,
                                  fit: BoxFit.contain, gaplessPlayback: true);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
