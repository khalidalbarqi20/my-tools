import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'pdf_common.dart';
import 'pdf_ops.dart';

class PdfPreviewPage extends StatefulWidget {
  const PdfPreviewPage({super.key});
  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  Picked? _file;
  PdfDocument? _doc;
  bool _busy = false;
  String? _err;
  final Map<int, Future<Uint8List?>> _cache = {};

  @override
  void dispose() {
    _doc?.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final f = await pickPicked(type: FileType.custom, exts: ['pdf']);
      if (f.isEmpty) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      ensurePdfInit();
      final d = await PdfDocument.openData(f.first.bytes, sourceName: f.first.name);
      if (!mounted) {
        await d.dispose();
        return;
      }
      final old = _doc;
      setState(() {
        _doc = d;
        _file = f.first;
        _cache.clear();
        _busy = false;
      });
      await old?.dispose();
    } catch (e) {
      if (mounted) {
        setState(() {
          _err = friendlyError(e);
          _busy = false;
        });
      }
    }
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
    final t = Theme.of(context);
    final doc = _doc;
    return Scaffold(
      appBar: AppBar(
        title: Text(_file?.name ?? 'معاينة PDF', overflow: TextOverflow.ellipsis),
        actions: [
          if (doc != null) ...[
            IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.share),
              onPressed: () => shareOut(
                  context, [OutFile(_file!.name, _file!.bytes, 'application/pdf')]),
            ),
            IconButton(
                tooltip: 'ملف آخر',
                icon: const Icon(Icons.folder_open),
                onPressed: _busy ? null : _pick),
          ],
        ],
      ),
      body: doc == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('اختيار ملف PDF'),
                  ),
                  if (_busy)
                    const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator()),
                  if (_err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
                    ),
                ]),
              ),
            )
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
                          return Image.memory(s.data!, fit: BoxFit.contain, gaplessPlayback: true);
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
