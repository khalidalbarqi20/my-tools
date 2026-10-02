import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'pdf_common.dart' show OutFile, Picked;

Future<Uint8List> _build(Map<String, Object> a) async {
  final imgs = (a['imgs'] as List).cast<Uint8List>();
  final landscape = a['landscape'] as bool;
  final fmt = landscape ? pdf.PdfPageFormat.a4.landscape : pdf.PdfPageFormat.a4;
  final doc = pw.Document();
  for (final b in imgs) {
    final img = pw.MemoryImage(b);
    doc.addPage(pw.Page(
      pageFormat: fmt,
      margin: const pw.EdgeInsets.all(16),
      build: (_) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
    ));
  }
  return doc.save();
}

Future<OutFile> imagesToPdf(List<Picked> imgs, {required bool landscape}) async {
  final data = await compute(_build, <String, Object>{
    'imgs': [for (final i in imgs) i.bytes],
    'landscape': landscape,
  });
  return OutFile('images.pdf', data, 'application/pdf');
}
