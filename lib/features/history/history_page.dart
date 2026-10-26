import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../storage/ops_history.dart';
import '../pdf/pdf_common.dart' show humanSize;
import '../video/video_engine.dart';

/// سطر «عملياتي السابقة» لوضعه في صفحة الإعدادات.
class OpsHistoryTile extends StatelessWidget {
  const OpsHistoryTile({super.key});
  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.history),
        title: const Text('عملياتي السابقة'),
        subtitle: const Text('نتائج العمليات المحفوظة مع خيار حفظها'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const HistoryPage())),
      );
}

String _two(int n) => n < 10 ? '0$n' : '$n';
String _when(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.year}/${_two(d.month)}/${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';
}

IconData _icon(String mime) {
  if (mime.startsWith('video/')) return Icons.movie_outlined;
  if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
  if (mime.startsWith('image/')) return Icons.image_outlined;
  return Icons.insert_drive_file_outlined;
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    OpsHistory.load();
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<bool> _ready(OpEntry e) async {
    final ok = await restoreOutput(e.path, e.id);
    if (!ok) _snack('الملف لم يعد موجودًا على الجهاز.');
    return ok;
  }

  Future<void> _save(OpEntry e) async {
    if (!await _ready(e)) return;
    if (kIsWeb) {
      await webSave(e.path, e.name, e.mime);
      _snack('تم تجهيز الملف للتنزيل');
      return;
    }
    try {
      final bytes = await readBytesFrom(e.path);
      final r = await FilePicker.saveFile(
          dialogTitle: 'حفظ الملف', fileName: e.name, bytes: bytes);
      _snack(r != null ? 'تم الحفظ' : 'تم الإلغاء');
    } catch (_) {
      _snack('تعذر حفظ الملف');
    }
  }

  Future<void> _share(OpEntry e) async {
    if (!await _ready(e)) return;
    if (kIsWeb) {
      final ok = await webShare(e.path, e.name, e.mime);
      if (!ok) _snack('المشاركة غير مدعومة في هذا المتصفح، استخدم زر حفظ.');
      return;
    }
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(e.path, mimeType: e.mime, name: e.name)],
      ));
    } catch (_) {
      _snack('تعذرت المشاركة');
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف كل العمليات السابقة؟'),
        content: const Text('تُحذف الملفات المحفوظة معها ولا يمكن استرجاعها.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) await OpsHistory.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('عملياتي السابقة'),
        actions: [
          IconButton(
              tooltip: 'حذف الكل',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmClear),
        ],
      ),
      body: ValueListenableBuilder<List<OpEntry>>(
        valueListenable: OpsHistory.items,
        builder: (context, list, _) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                    'ما فيه عمليات محفوظة بعد.\nنتائج قص وتحويل الفيديو والصوت تظهر هنا تلقائيًا.',
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyMedium
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in list)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(_icon(e.mime)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.name, overflow: TextOverflow.ellipsis),
                            Text('${e.tool} • ${humanSize(e.size)} • ${_when(e.ts)}',
                                style: t.textTheme.bodySmall
                                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        FilledButton.tonalIcon(
                            onPressed: () => _save(e),
                            icon: const Icon(Icons.save_alt),
                            label: const Text('حفظ النتيجة')),
                        OutlinedButton.icon(
                            onPressed: () => _share(e),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('مشاركة')),
                        TextButton.icon(
                            onPressed: () => OpsHistory.remove(e),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('حذف')),
                      ]),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
