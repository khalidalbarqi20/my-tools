import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class QrCodePainter extends CustomPainter {
  final QrImage image;
  final int quiet;
  QrCodePainter(this.image, {this.quiet = 2});
  @override
  void paint(Canvas canvas, Size size) {
    final n = image.moduleCount;
    final cell = size.width / (n + quiet * 2);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final p = Paint()..color = Colors.black;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (image.isDark(r, c)) {
          canvas.drawRect(
              Rect.fromLTWH((c + quiet) * cell, (r + quiet) * cell, cell + 0.4,
                  cell + 0.4),
              p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(QrCodePainter old) => old.image != image;
}

/// صورة PNG بحجم تقريبي 1024 بكسل، أسود على أبيض مع هامش هادئ.
Future<Uint8List> qrPng(QrImage image, {int target = 1024, int quiet = 4}) async {
  final n = image.moduleCount;
  final total = n + quiet * 2;
  final cell = (target ~/ total).clamp(4, 64).toInt();
  final size = cell * total;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..color = Colors.white);
  final p = Paint()
    ..color = Colors.black
    ..isAntiAlias = false;
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      if (image.isDark(r, c)) {
        canvas.drawRect(
            Rect.fromLTWH(((c + quiet) * cell).toDouble(),
                ((r + quiet) * cell).toDouble(), cell.toDouble(), cell.toDouble()),
            p);
      }
    }
  }
  final pic = rec.endRecording();
  final img = await pic.toImage(size, size);
  pic.dispose();
  try {
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) throw Exception('encode failed');
    return bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
  } finally {
    img.dispose();
  }
}
