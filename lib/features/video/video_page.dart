import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../pdf/pdf_common.dart' show baseName, friendlyError, humanSize;
import '../pdf/single_pdf_tool.dart' show Opt, buildOptField;
import 'video_engine.dart';
import 'video_logic.dart';
import 'video_preview.dart';

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
  /// معاينة الملف مع شريط بداية/نهاية متحركين (لأداة القص) بدل كتابة الأوقات.
  final bool trimPicker;
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
    this.trimPicker = false,
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
  Job? _out, _base;
  int _outSize = 0;
  late final Map<String, String> _o = {for (final o in widget.options) o.key: o.initial};
  late final Map<String, TextEditingController> _tc = {
    for (final o in widget.options)
      if (!o.isSwitch && o.choices == null) o.key: TextEditingController(text: o.initial)
  };

  @override
  void dispose() {
    if (_busy) cancelFfmpeg();
    final out = _out, base = _base;
    if (out != null) deleteQuiet(out.outPath);
    if (base != null && base != out) deleteQuiet(base.outPath);
    for (final c in _tc.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _clearOut() async {
    final out = _out, base = _base;
    _out = null;
    _base = null;
    if (out != null) await deleteQuiet(out.outPath);
    if (base != null && base != out) await deleteQuiet(base.outPath);
  }

  Future<void> _pick() async {
    setState(() => _err = null);
    try {
      String? p, name;
      if (kIsWeb) {
        final w = await webPick(widget.pickType == FileType.video
            ? 'video'
            : widget.pickType == FileType.audio
                ? 'audio'
                : 'any');
        if (w == null) return;
        p = w.$1;
        name = w.$2;
      } else {
        final files = await FilePicker.pickFiles(type: widget.pickType);
        if (files.isEmpty) return;
        final f = files.first;
        p = f.path;
        name = f.name;
      }
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
        _name = name;
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
        _base = job;
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

  static const _exportVideo = [
    ('mp4', 'MP4'),
    ('mkv', 'MKV'),
    ('mov', 'MOV'),
    ('webm', 'WEBM'),
    ('avi', 'AVI'),
    ('gif', 'GIF'),
  ];

  Future<({String kind, String key, String q})?> _askExport(Job base) {
    final isVideo = base.mime.startsWith('video/');
    String? kind, key;
    String vq = '5', aq = '192';
    return showModalBottomSheet<({String kind, String key, String q})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        Widget chips(String k, List<(String, String)> items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in items)
                  ChoiceChip(
                    label: Text(e.$2),
                    selected: kind == k && key == e.$1,
                    onSelected: (_) => set(() {
                      kind = k;
                      key = e.$1;
                    }),
                  ),
              ],
            );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تصدير بصيغة', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (_out != base)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ActionChip(
                      avatar: const Icon(Icons.undo, size: 18),
                      label: const Text('العودة للملف الأصلي'),
                      onPressed: () => Navigator.pop(ctx, (kind: 'orig', key: '', q: '')),
                    ),
                  ),
                if (isVideo) ...[
                  const Text('فيديو'),
                  const SizedBox(height: 6),
                  chips('video', _exportVideo),
                  const SizedBox(height: 12),
                ],
                Text(isVideo ? 'صوت فقط' : 'الصيغ'),
                const SizedBox(height: 6),
                chips('audio', audioFormats),
                const SizedBox(height: 12),
                if (kind == 'video') ...[
                  const Text('الجودة'),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '2', label: Text('عالية')),
                      ButtonSegment(value: '5', label: Text('متوسطة')),
                      ButtonSegment(value: '9', label: Text('أقل حجمًا')),
                    ],
                    selected: {vq},
                    onSelectionChanged: (s) => set(() => vq = s.first),
                  ),
                ],
                if (kind == 'audio') ...[
                  const Text('جودة الصوت (للصيغ المضغوطة)'),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '128', label: Text('128')),
                      ButtonSegment(value: '192', label: Text('192')),
                      ButtonSegment(value: '256', label: Text('256')),
                      ButtonSegment(value: '320', label: Text('320')),
                    ],
                    selected: {aq},
                    onSelectionChanged: (s) => set(() => aq = s.first),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: key == null
                        ? null
                        : () => Navigator.pop(
                            ctx, (kind: kind!, key: key!, q: kind == 'video' ? vq : aq)),
                    child: const Text('تصدير'),
                  ),
                ),
              ]),
        );
      }),
    );
  }

  Future<void> _export() async {
    final base = _base;
    if (base == null || _busy) return;
    final s = await _askExport(base);
    if (s == null || !mounted) return;
    if (s.kind == 'orig') {
      final cur = _out;
      final sz = await fileSize(base.outPath);
      if (cur != null && cur != base) await deleteQuiet(cur.outPath);
      if (mounted) {
        setState(() {
          _out = base;
          _outSize = sz;
        });
      }
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
      _progress = 0;
    });
    String? tmp;
    try {
      double? dur;
      try {
        dur = (await probeMedia(base.outPath)).duration;
      } catch (_) {}
      final String name, mime;
      final List<String> args;
      if (s.kind == 'video') {
        if (s.key == 'gif' && (dur ?? 0) > 60) {
          throw const FormatException('تحويل GIF للمقاطع حتى 60 ثانية. قصّ المقطع أولًا.');
        }
        tmp = tempPath(s.key);
        args = convertVideoArgs(base.outPath, tmp, s.key, s.q);
        mime = videoMime(s.key);
        name = '${baseName(base.name)}.${s.key}';
      } else {
        final f = audioFmt(s.key, int.parse(s.q));
        tmp = tempPath(f.ext);
        args = extractAudioArgs(base.outPath, tmp, f);
        mime = f.mime;
        name = '${baseName(base.name)}.${f.ext}';
      }
      await runFfmpeg(args, totalSec: dur, onProgress: (v) {
        if (mounted) setState(() => _progress = v);
      });
      final sz = await fileSize(tmp);
      if (sz <= 0) throw const FormatException('لم يُنتج الملف. جرّب صيغة أخرى.');
      final job = Job(args, tmp, mime, name: name);
      final old = _out;
      if (!mounted) {
        await deleteQuiet(tmp);
        return;
      }
      if (old != null && old != base) await deleteQuiet(old.outPath);
      setState(() {
        _out = job;
        _outSize = sz;
      });
    } catch (e) {
      if (tmp != null) await deleteQuiet(tmp);
      if (mounted) {
        setState(() => _err = e is FormatException
            ? friendlyError(e)
            : 'تعذر التصدير بهذه الصيغة. إذا كان الملف بلا صوت فاختر صيغة فيديو.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final out = _out;
    if (out == null) return;
    if (kIsWeb) {
      await webSave(out.outPath, out.name, out.mime);
      _snack('تم تجهيز الملف للتنزيل');
      return;
    }
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
    if (kIsWeb) {
      final ok = await webShare(out.outPath, out.name, out.mime);
      if (!ok) _snack('المشاركة غير مدعومة في هذا المتصفح، استخدم زر حفظ.');
      return;
    }
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
            if (widget.trimPicker && _path != null && info != null)
              TrimPicker(
                key: ValueKey(_path),
                path: _path!,
                video: info.hasVideo,
                onChanged: (s, e) {
                  _o['start'] = s.toStringAsFixed(3);
                  _o['end'] = e == null ? '' : e.toStringAsFixed(3);
                },
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
                    Text(
                        out.mustShrink
                            ? '${humanSize(_size)}  ←  ${humanSize(_outSize)}'
                            : humanSize(_outSize),
                        style: t.textTheme.bodySmall
                            ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    MediaPreview(
                      key: ValueKey(out.outPath),
                      path: out.outPath,
                      video: out.mime.startsWith('video/'),
                      gif: out.mime == 'image/gif',
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (kIsWeb)
                        FilledButton.tonalIcon(
                            onPressed: () => webPreview(out.outPath, out.mime),
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('معاينة')),
                      FilledButton.tonalIcon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('حفظ')),
                      OutlinedButton.icon(
                          onPressed: _busy ? null : _export,
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('تصدير بصيغة')),
                      OutlinedButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('مشاركة')),
                    ]),
                  ]),
                ),
              ),
          ],
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                  'على الويب تتم المعالجة داخل المتصفح بدون رفع الملفات. قد يُنزَّل محرك إضافي في أول استخدام، والملفات الكبيرة جدًا أسرع وأضمن في تطبيق الأندرويد.',
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ),
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
