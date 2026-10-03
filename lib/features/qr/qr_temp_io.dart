import 'dart:io';
import 'dart:typed_data';

/// يكتب الصورة في مجلد مؤقت (بجانب الملف الأصلي أو المجلد المؤقت للنظام).
Future<String?> writeTempPng(Uint8List bytes, String? near) async {
  final name = 'qr_crop_${DateTime.now().millisecondsSinceEpoch}.png';
  final dirs = <String>[
    if (near != null && near.isNotEmpty) File(near).parent.path,
    Directory.systemTemp.path,
  ];
  for (final d in dirs) {
    try {
      final f = File('$d/$name');
      await f.writeAsBytes(bytes, flush: true);
      return f.path;
    } catch (_) {
      // جرّب المسار التالي
    }
  }
  return null;
}

Future<void> deleteTemp(String? path) async {
  if (path == null) return;
  try {
    await File(path).delete();
  } catch (_) {
    // لا يهم
  }
}
