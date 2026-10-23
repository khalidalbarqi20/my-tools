import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

export 'result_list.dart' show ResultList;

bool _inited = false;
void ensurePdfInit() {
  if (!_inited) {
    pdfrxFlutterInitialize();
    _inited = true;
  }
}

class OutFile {
  final String name;
  final Uint8List bytes;
  final String mime;
  const OutFile(this.name, this.bytes, this.mime);
}

class Picked {
  final String name;
  final Uint8List bytes;
  const Picked(this.name, this.bytes);
}

String baseName(String n) {
  final i = n.lastIndexOf('.');
  return i > 0 ? n.substring(0, i) : n;
}

String humanSize(int b) {
  if (b < 1024) return '$b B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
  return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
}

String friendlyError(Object e) {
  if (e is FormatException) return e.message;
  if (e.toString().toLowerCase().contains('password')) {
    return 'الملف محمي بكلمة مرور ولا يمكن فتحه';
  }
  return 'تعذر معالجة الملف. تأكد من أن الملف صالح ثم حاول مرة أخرى.';
}

Future<List<Picked>> pickPicked(
    {required FileType type, List<String>? exts}) async {
  final files = await FilePicker.pickFiles(type: type, allowedExtensions: exts);
  return [for (final f in files) Picked(f.name, await f.readAsBytes())];
}

Future<void> saveOut(BuildContext context, OutFile f) async {
  String msg;
  try {
    final r = await FilePicker.saveFile(
        dialogTitle: 'حفظ الملف', fileName: f.name, bytes: f.bytes);
    msg = r != null ? 'تم الحفظ' : (kIsWeb ? 'تم التنزيل' : 'تم الإلغاء');
  } catch (_) {
    msg = 'تعذر حفظ الملف';
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

Future<void> shareOut(BuildContext context, List<OutFile> fs) async {
  try {
    await SharePlus.instance.share(ShareParams(
      files: [
        for (final f in fs)
          XFile.fromData(f.bytes, mimeType: f.mime, name: f.name)
      ],
      fileNameOverrides: [for (final f in fs) f.name],
    ));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح قائمة المشاركة')));
    }
  }
}
