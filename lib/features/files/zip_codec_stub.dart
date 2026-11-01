import 'dart:typed_data';

/// بدون ضغط (يُخزَّن الملف كما هو).
Future<Uint8List> deflateRaw(Uint8List b) async => b;
Future<Uint8List> inflateRaw(Uint8List b) async =>
    throw UnsupportedError('فك الضغط غير مدعوم على هذه المنصة');
