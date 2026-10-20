import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../pdf/pdf_common.dart' show friendlyError, humanSize;
import '../pdf/single_pdf_tool.dart' show Opt, buildOptField;
import 'video_engine.dart';
import 'video_logic.dart';

/// بيانات الملف المختار والخيارات، تُمرَّر لدالة بناء المهمة.
class MediaCtx {
  final String path, name;
  final ProbeInfo info;
  final int size;
  final Map<String, String> o;
  const MediaCtx(this.path, this.name, this.info, this.size, this.o);
}

typedef JobBuilder = Future<Job> Function(MediaCtx c);

/// صفحة عامة لكل أدوات الفيديو والصوت: اختيار ملف، خيارات، تنفيذ مع تقدم، ثم حفظ/مشاركة.
class MediaToolPage extends StatefulWidget {
  final String title, actionLabel, pickLabel;
  final FileType pickType;
  final List<Opt> options;
  final JobBuilder build;
  final bool needAudio, needVideo;
  final String? note;
  const MediaToolPage({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.build,
    this.options = const [],
    this.pickType = FileType.any,
    this.pickLabel = 'اختيار ملف',
    this.needAudio = false,
    this.needVideo = false,
    this.note,
  });
  @override
  State<MediaToolPage> createState() => _MediaToolPageState();
}

class _MediaToolPageState extends State<MediaToolPage> {
  String? _path, _name, _err;
  ProbeInfo? _info;
  int _size = 0;
  bool _busy = false;
  double _progress = 0;
  Job? _out;
  int _outSize = 0;
  late final Map<String, String> _o = {for (final o in widget.options) o.key: o.initial};
  late final Map<String, TextEditingController> _tc = {
    for (final o in widget.options)
      if (!o.isSwitch && o.choices == null) o.key: TextEditingController(text: o.initial)
  };

  @override
  void dispose() {
    if (_busy) cancelFfmpeg();
    final out = _out;
    if (out != null) deleteQuiet(out.outPath);
    for (final c in _tc.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _clearOut() async {
    final out = _out;
    _out = null;
    if (out != null) await deleteQuiet(out.outPath);
  }

  Future<void> _pick() async {
    setState(() => _err = null);
    try {
      final files = await FilePicker.pickFiles(type: widget.pickType);
      if (files.isEmpty) return;
      final f = files.first;
      final p = f.path;
      if (p == null) throw const FormatException('تعذر الوصول إلى الملف');
      final info = await probeMedia(p);
      if (widget.needAudio && !info.hasAudio) {
        throw const FormatException('هذا الملف لا يحتوي على مسار صوت.');
      }
      if (widget.needVideo && !info.hasVideo) {
        throw const FormatException('هذا الملف لا يحتوي على فيديو.');
      }
      final size = await fileSize(p);
      await _clearOut();
      if (!mounted) return;
      setState(() {
        _path = p;
        _name = f.name;
        _info = info;
        _size = size;
      });
    } catch (e) {
      if (mounted) setState(() => _err = friendlyError(e));
    }
  }

  Future<void> _run() async {
    final p = _path, info = _info;
    if (p == null || info == null) return;
    setState(() {
      _busy = true;
      _err = null;
      _progress = 0;
    });
    await _clearOut();
    Job? job;
    try {
      for (final e in _tc.entries) {
        _o[e.key] = e.value.text;
      }
      job = await widget.build(MediaCtx(p, _name ?? 'file', info, _size, Map.of(_o)));
      await runFfmpeg(job.args,
          totalSec: job.totalSec ?? info.duration,
          onProgress: (v) {
            if (mounted) setState(() => _progress = v);
          });
      final sz = await fileSize(job.outPath);
      if (sz <= 0) throw const FormatException('لم يُنتج الملف. جرّب إعدادات أخرى.');
      if (job.mustShrink && sz >= _size) {
        await deleteQuiet(job.outPath);
        throw const FormatException(
            'الملف مضغوط أصلًا والناتج أكبر من الأصلي، لذلك لم يُحفظ. جرّب جودة أقل أو دقة أصغر.');
      }
      if (!mounted) {
        await deleteQuiet(job.outPath);
        return;
      }
      setState(() {
        _out = job;
        _outSize = sz;
      });
    } catch (e) {
      if (job != null) await deleteQuiet(job.outPath);
      if (mounted) setState(() => _err = friendlyError(e));
    } finally {
      if (job != null) {
        for (final t in job.temps) {
          await deleteQuiet(t);
        }
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _save() async {
    final out = _out;
    if (out == null) return;
    if (_outSize > 200 * 1024 * 1024) {
      _snack('الملف كبير، استخدم المشاركة لحفظه.');
      return;
    }
    try {
      final bytes = await readBytesFrom(out.outPath);
      final r = await FilePicker.saveFile(
          dialogTitle: 'حفظ الملف', fileName: out.name, bytes: bytes);
      _snack(r != null ? 'تم الحفظ' : 'تم الإلغاء');
    } catch (_) {
      _snack('تعذر حفظ الملف');
    }
  }

  Future<void> _share() async {
    final out = _out;
    if (out == null) return;
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(out.outPath, mimeType: out.mime, name: out.name)],
      ));
    } catch (_) {
      _snack('تعذرت المشاركة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final info = _info;
    final out = _out;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!engineSupported)
            Text('أدوات الفيديو والصوت تعمل في تطبيق الأندرويد فقط.',
                style: TextStyle(color: t.colorScheme.error))
          else ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.folder_open),
              label: Text(_path == null ? widget.pickLabel : 'تغيير الملف'),
            ),
            if (_name != null && info != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(info.hasVideo ? Icons.movie_outlined : Icons.audiotrack_outlined),
                title: Text(_name!, overflow: TextOverflow.ellipsis),
                subtitle: Text([
                  if (info.duration != null) fmtClock(info.duration!),
                  if (info.hasVideo && info.width != null) '${info.width}×${info.height}',
                  humanSize(_size),
                ].join(' • ')),
              ),
            const SizedBox(height: 8),
            for (final o in widget.options) ...[
              buildOptField(o, _o, _tc, () => setState(() {})),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: (_path == null || _busy) ? null : _run,
              child: Text(widget.actionLabel),
            ),
            if (_busy) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              ),
              TextButton(onPressed: cancelFfmpeg, child: const Text('إلغاء')),
            ],
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
              ),
            if (out != null)
              Card(
                margin: const EdgeInsets.only(top: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(out.name, overflow: TextOverflow.ellipsis),
                    Text(humanSize(_outSize),
                        style: t.textTheme.bodySmall
                            ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(children: [
                      FilledButton.tonalIcon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('حفظ')),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('مشاركة')),
                    ]),
                  ]),
                ),
              ),
          ],
          if (widget.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(widget.note!,
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
