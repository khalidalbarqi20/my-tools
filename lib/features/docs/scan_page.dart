import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import '../pdf/pdf_common.dart' show OutFile, pickPicked, saveOut, shareOut;
import 'scan_logic.dart';

const _maxSide = 1800;
const _maxPages = 30;

class _Pg {
  final Uint8List orig;
  int turns = 0;
  Uint8List? png;
  int w = 0, h = 0;
  _Pg(this.orig);
}

Future<(Uint8List, int, int)> _decode(Uint8List bytes) async {
  final buf = await ui.ImmutableBuffer.fromUint8List(bytes);
  final desc = await ui.ImageDescriptor.encoded(buf);
  final k = math.min(1.0, _maxSide / math.max(desc.width, desc.height));
  final codec = await desc.instantiateCodec(
      targetWidth: (desc.width * k).round(), targetHeight: (desc.height * k).round());
  final fr = await codec.getNextFrame();
  final img = fr.image;
  final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  final w = img.width, h = img.height;
  img.dispose();
  codec.dispose();
  desc.dispose();
  buf.dispose();
  if (bd == null) throw Exception('decode failed');
  return (bd.buffer.asUint8List(), w, h);
}

Future<Uint8List> _encodePng(Uint8List rgba, int w, int h) async {
  final buf = await ui.ImmutableBuffer.fromUint8List(rgba);
  final desc = ui.ImageDescriptor.raw(buf, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
  final codec = await desc.instantiateCodec();
  final fr = await codec.getNextFrame();
  final data = await fr.image.toByteData(format: ui.ImageByteFormat.png);
  fr.image.dispose();
  codec.dispose();
  desc.dispose();
  buf.dispose();
  if (data == null) throw Exception('encode failed');
  return data.buffer.asUint8List();
}

Uint8List _enh(List<Object> a) => enhanceDocument(a[0] as Uint8List, a[1] as int, a[2] as int, a[3] as ScanMode);

Future<Uint8List> _buildPdf(List<Object> a) async {
  final pngs = (a[0] as List).cast<Uint8List>();
  final sizes = (a[1] as List).cast<List<int>>();
  final doc = pw.Document();
  for (var i = 0; i < pngs.length; i++) {
    final fmt = pdf.PdfPageFormat(sizes[i][0] * 72 / 150, sizes[i][1] * 72 / 150);
    final img = pw.MemoryImage(pngs[i]);
    doc.addPage(pw.Page(
      pageFormat: fmt,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(img, fit: pw.BoxFit.fill),
    ));
  }
  return doc.save();
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final List<_Pg> _pages = [];
  ScanMode _mode = ScanMode.doc;
  bool _busy = false;
  String? _e;

  Future<void> _render(_Pg p) async {
    var (rgba, w, h) = await _decode(p.orig);
    rgba = await compute(_enh, <Object>[rgba, w, h, _mode]);
    for (var i = 0; i < p.turns % 4; i++) {
      final r = rotateRgbaCw(rgba, w, h);
      rgba = r.$1;
      w = r.$2;
      h = r.$3;
    }
    p.png = await _encodePng(rgba, w, h);
    p.w = w;
    p.h = h;
  }

  Future<void> _addBytes(List<Uint8List> list) async {
    if (list.isEmpty) return;
    setState(() {
      _busy = true;
      _e = null;
    });
    try {
      for (final b in list) {
        if (_pages.length >= _maxPages) {
          throw const FormatException('الحد الأقصى ٣٠ صفحة.');
        }
        final p = _Pg(b);
        await _render(p);
        _pages.add(p);
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) setState(() => _e = e is FormatException ? e.message : 'تعذر قراءة الصورة.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _camera() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 3000, imageQuality: 92);
      if (x == null) return;
      await _addBytes([await x.readAsBytes()]);
    } catch (_) {
      if (mounted) setState(() => _e = 'تعذر فتح الكاميرا. اسمح بالوصول للكاميرا أو اختر من المعرض.');
    }
  }

  Future<void> _gallery() async {
    try {
      final fs = await pickPicked(type: FileType.image);
      await _addBytes([for (final f in fs) f.bytes]);
    } catch (_) {
      if (mounted) setState(() => _e = 'تعذر قراءة الصور.');
    }
  }

  Future<void> _rerender() async {
    setState(() {
      _busy = true;
      _e = null;
    });
    try {
      for (final p in _pages) {
        await _render(p);
        if (mounted) setState(() {});
      }
    } catch (_) {
      if (mounted) setState(() => _e = 'تعذر تطبيق الفلتر.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<OutFile?> _pdf() async {
    if (_pages.isEmpty) return null;
    setState(() => _busy = true);
    try {
      final b = await compute(_buildPdf, <Object>[
        [for (final p in _pages) p.png!],
        [for (final p in _pages) [p.w, p.h]],
      ]);
      return OutFile('scan.pdf', b, 'application/pdf');
    } catch (_) {
      if (mounted) setState(() => _e = 'تعذر إنشاء الملف.');
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ماسح المستندات')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(
              child: FilledButton.icon(
                  onPressed: _busy ? null : _camera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('تصوير'))),
          const SizedBox(width: 8),
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: _busy ? null : _gallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('من المعرض'))),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final m in ScanMode.values)
            ChoiceChip(
              label: Text(scanModeNames[m]!),
              selected: _mode == m,
              onSelected: _busy
                  ? null
                  : (_) {
                      setState(() => _mode = m);
                      _rerender();
                    },
            ),
        ]),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (_e != null)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(_e!, style: TextStyle(color: t.colorScheme.error))),
        const SizedBox(height: 12),
        if (_pages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text('صوّر ورقة أو اختر صورًا، وتتحسن تلقائيًا ثم تحوّلها إلى PDF.',
                textAlign: TextAlign.center,
                style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
        for (var i = 0; i < _pages.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(children: [
              if (_pages[i].png != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.memory(_pages[i].png!, height: 260, fit: BoxFit.contain),
                ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('صفحة ${i + 1}'),
                IconButton(
                    tooltip: 'تدوير',
                    onPressed: _busy
                        ? null
                        : () async {
                            _pages[i].turns++;
                            await _rerenderOne(_pages[i]);
                          },
                    icon: const Icon(Icons.rotate_right)),
                IconButton(
                    tooltip: 'للأعلى',
                    onPressed: i == 0 ? null : () => setState(() => _pages.insert(i - 1, _pages.removeAt(i))),
                    icon: const Icon(Icons.arrow_upward)),
                IconButton(
                    tooltip: 'للأسفل',
                    onPressed: i == _pages.length - 1 ? null : () => setState(() => _pages.insert(i + 1, _pages.removeAt(i))),
                    icon: const Icon(Icons.arrow_downward)),
                IconButton(
                    tooltip: 'حذف',
                    onPressed: () => setState(() => _pages.removeAt(i)),
                    icon: const Icon(Icons.delete_outline)),
              ]),
            ]),
          ),
        if (_pages.isNotEmpty) ...[
          FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final f = await _pdf();
                      if (f != null && context.mounted) await saveOut(context, f);
                    },
              icon: const Icon(Icons.picture_as_pdf),
              label: Text('حفظ PDF (${_pages.length} صفحة)')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final f = await _pdf();
                      if (f != null && context.mounted) await shareOut(context, [f]);
                    },
              icon: const Icon(Icons.share),
              label: const Text('مشاركة')),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
              'المعالجة داخل جهازك ولا تُرفع الصور. التحسين يعادل الظلال ويبيّض الورق، لكنه لا يقص حواف الورقة تلقائيًا؛ صوّر الورقة قريبة وبإضاءة جيدة. إن ظهرت الصورة مقلوبة استخدم زر التدوير.',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
      ]),
    );
  }

  Future<void> _rerenderOne(_Pg p) async {
    setState(() => _busy = true);
    try {
      await _render(p);
    } catch (_) {
      if (mounted) setState(() => _e = 'تعذر التدوير.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
