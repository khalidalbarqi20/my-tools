import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../image/image_common.dart' show imageSize;
import 'qr_crop_page.dart';
import 'qr_logic.dart';
import 'qr_result_sheet.dart';
import 'qr_temp_stub.dart' if (dart.library.io) 'qr_temp_io.dart';

class _ScanOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.68;
    final rect = Rect.fromCenter(
        center: size.center(Offset.zero), width: side, height: side);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rr)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_ScanOverlay old) => false;
}

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _c = MobileScannerController();
  bool _showing = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _present(String v, bool isQr) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => QrResultSheet(p: parseQr(v), isQr: isQr),
    );
  }

  Future<void> _scanned(String v, bool isQr) async {
    _showing = true;
    HapticFeedback.mediumImpact();
    await _present(v, isQr);
    _showing = false;
  }

  void _onDetect(BarcodeCapture cap) {
    if (_showing) return;
    for (final b in cap.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        _scanned(v, b.format == BarcodeFormat.qrCode);
        return;
      }
    }
  }

  Future<void> _gallery() async {
    if (_showing) return;
    _showing = true; // نوقف قراءة الكاميرا أثناء التعديل
    String? temp;
    try {
      final fs = await FilePicker.pickFiles(type: FileType.image);
      if (fs.isEmpty) return;
      final f = fs.first;
      final bytes = await f.readAsBytes();
      final dims = await imageSize(bytes);
      if (!mounted) return;
      final edited = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => QrCropPage(bytes: bytes, dims: dims)),
      );
      if (edited == null) return;
      temp = await writeTempPng(edited, f.path);
      if (temp == null) {
        _toast('قراءة الرمز من الصور غير مدعومة هنا. استخدم الكاميرا.');
        return;
      }
      final cap = await _c.analyzeImage(temp);
      String? v;
      var isQr = true;
      for (final b in cap?.barcodes ?? <Barcode>[]) {
        final raw = b.rawValue;
        if (raw != null && raw.isNotEmpty) {
          v = raw;
          isQr = b.format == BarcodeFormat.qrCode;
          break;
        }
      }
      if (v == null) {
        _toast('ما لقينا رمز. جرّب قص الصورة أقرب للرمز أو فعّل عكس الألوان.');
        return;
      }
      await _present(v, isQr);
    } catch (_) {
      _toast('تعذر قراءة الصورة');
    } finally {
      await deleteTemp(temp);
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('قارئ QR والباركود'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _c,
            builder: (context, s, child) {
              final on = s.torchState == TorchState.on;
              final na = s.torchState == TorchState.unavailable;
              return IconButton(
                tooltip: 'الفلاش',
                icon: Icon(on ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white),
                onPressed: na ? null : () => _c.toggleTorch(),
              );
            },
          ),
          IconButton(
            tooltip: 'من المعرض',
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            onPressed: _gallery,
          ),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        MobileScanner(controller: _c, onDetect: _onDetect),
        CustomPaint(painter: _ScanOverlay()),
        const Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Text('وجّه الكاميرا نحو رمز QR أو باركود',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        ValueListenableBuilder<MobileScannerState>(
          valueListenable: _c,
          builder: (context, s, child) {
            if (s.error == null) return const SizedBox.shrink();
            return Container(
              color: Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.no_photography_outlined,
                    color: Colors.white70, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'تعذر تشغيل الكاميرا. تأكد من منح التطبيق إذن الكاميرا من إعدادات الجهاز.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 220,
                  child: FilledButton(
                    onPressed: () => _c.start(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ),
              ]),
            );
          },
        ),
      ]),
    );
  }
}
