import 'dart:io';

/// مجلد بيانات التطبيق الدائم (أندرويد: files داخل مجلد التطبيق). يُستخدم في أندرويد/آيفون فقط.
String appDataDir() {
  if (Platform.isAndroid) return '${Directory.systemTemp.parent.path}/files';
  return Directory.systemTemp.path;
}
