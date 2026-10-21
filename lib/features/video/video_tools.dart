import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/tool.dart';
import '../pdf/pdf_common.dart' show baseName;
import '../pdf/single_pdf_tool.dart' show Opt;
import 'video_engine.dart';
import 'video_logic.dart';
import 'video_page.dart';
import 'video_text_png.dart';

const _note =
    'المعالجة تتم على جوالك بدون إنترنت، وقد تستغرق وقتًا حسب طول الملف وقوة الجهاز. '
    'ناتج الفيديو بترميز MPEG-4 المتوافق مع كل الأجهزة، وحجمه أكبر من H.264.';

Tool _t(String id, String ar, String en, List<String> kw, IconData icon, WidgetBuilder b) =>
    Tool(id: id, nameAr: ar, nameEn: en, category: 'video', keywords: kw, icon: icon, builder: b);

const _kbps = Opt.choice('kbps', 'جودة الصوت (للصيغ المضغوطة)',
    [('128', '128'), ('192', '192'), ('256', '256'), ('320', '320')],
    initial: '192');

Future<Job> _extract(MediaCtx c) async {
  final f = audioFmt(c.o['fmt']!, int.parse(c.o['kbps']!));
  final out = tempPath(f.ext);
  return Job(extractAudioArgs(c.path, out, f), out, f.mime,
      name: '${baseName(c.name)}.${f.ext}');
}

Future<Job> _trim(MediaCtx c) async {
  final sRaw = (c.o['start'] ?? '').trim(), eRaw = (c.o['end'] ?? '').trim();
  final s = sRaw.isEmpty ? 0.0 : parseClock(sRaw);
  final e = eRaw.isEmpty ? null : parseClock(eRaw);
  if (s == null || (eRaw.isNotEmpty && e == null)) {
    throw const FormatException('اكتب الوقت بصيغة 1:30 أو 90 (بالثواني)');
  }
  final d = c.info.duration;
  if (d != null && s >= d) {
    throw FormatException('وقت البداية بعد نهاية الملف (مدته ${fmtClock(d)})');
  }
  var end = e;
  if (end != null && d != null && end > d) end = d;
  if (end != null && end <= s) {
    throw const FormatException('وقت النهاية يجب أن يكون بعد وقت البداية');
  }
  final audioOnly = !c.info.hasVideo;
  final precise = c.o['precise'] == 'true' && !audioOnly;
  final ext = trimExt(c.name, precise: precise, audioOnly: audioOnly);
  final out = tempPath(ext);
  return Job(trimArgs(c.path, out, start: s, end: end, precise: precise), out,
      audioOnly ? 'audio/$ext' : videoMime(ext),
      name: '${baseName(c.name)}_cut.$ext', totalSec: (end ?? d ?? 0) - s);
}

Future<Job> _text(MediaCtx c) async {
  final text = (c.o['text'] ?? '').trim();
  if (text.isEmpty) throw const FormatException('اكتب النص أولًا');
  final w = c.info.width, h = c.info.height;
  if (w == null || h == null) throw const FormatException('تعذر قراءة أبعاد الفيديو');
  final fRaw = (c.o['from'] ?? '').trim(), tRaw = (c.o['to'] ?? '').trim();
  final from = fRaw.isEmpty ? null : parseClock(fRaw);
  final to = tRaw.isEmpty ? null : parseClock(tRaw);
  if ((fRaw.isNotEmpty && from == null) || (tRaw.isNotEmpty && to == null)) {
    throw const FormatException('اكتب الوقت بصيغة 1:30 أو 90 (بالثواني)');
  }
  if (from != null && to != null && to <= from) {
    throw const FormatException('وقت الانتهاء يجب أن يكون بعد وقت الظهور');
  }
  final png = tempPath('png');
  await writeBytesTo(
      png,
      await renderTextOverlay(
        text: text,
        w: w,
        h: h,
        pos: c.o['pos']!,
        size: c.o['size']!,
        color: c.o['color']!,
        box: c.o['box'] == 'true',
      ));
  final out = tempPath('mp4');
  return Job(overlayArgs(c.path, png, out, start: from, end: to), out, 'video/mp4',
      name: '${baseName(c.name)}_text.mp4', temps: [png]);
}

Future<Job> _convert(MediaCtx c) async {
  final fmt = c.o['fmt']!;
  if (fmt == 'gif' && (c.info.duration ?? 0) > 60) {
    throw const FormatException('تحويل GIF للمقاطع حتى 60 ثانية. قصّ المقطع أولًا.');
  }
  final out = tempPath(fmt);
  return Job(convertVideoArgs(c.path, out, fmt, c.o['q']!), out, videoMime(fmt),
      name: '${baseName(c.name)}.$fmt');
}

Future<Job> _compress(MediaCtx c) async {
  final out = tempPath('mp4');
  return Job(compressArgs(c.path, out, int.parse(c.o['h']!), c.o['q']!), out, 'video/mp4',
      name: '${baseName(c.name)}_small.mp4', mustShrink: true);
}

Future<Job> _mute(MediaCtx c) async {
  final i = c.name.lastIndexOf('.');
  final e = i > 0 ? c.name.substring(i + 1).toLowerCase() : 'mp4';
  final ext = const {'mp4', 'mov', 'mkv', 'webm', '3gp', 'm4v'}.contains(e) ? e : 'mp4';
  final out = tempPath(ext);
  return Job(muteArgs(c.path, out), out, videoMime(ext),
      name: '${baseName(c.name)}_mute.$ext');
}

Future<Job> _audioToVideo(MediaCtx c) async {
  final size = c.o['size']!, bg = c.o['bg']!;
  final out = tempPath('mp4');
  return Job(audioToVideoArgs(c.path, out, size, bg), out, 'video/mp4',
      name: '${baseName(c.name)}_video.mp4');
}

final List<Tool> videoTools = [
  _t('vid_to_audio', 'استخراج الصوت من الفيديو', 'Extract Audio',
      ['استخراج', 'صوت', 'mp3', 'ام بي 3', 'فيديو إلى صوت', 'mp4', 'اغنية', 'extract', 'audio', 'video to mp3'],
      Icons.audiotrack_outlined,
      (_) => const MediaToolPage(
            title: 'استخراج الصوت من الفيديو',
            actionLabel: 'استخراج',
            pickLabel: 'اختيار فيديو',
            pickType: FileType.video,
            needAudio: true,
            build: _extract,
            options: [
              Opt.choice('fmt', 'الصيغة', audioFormats, initial: 'mp3'),
              _kbps,
            ],
            note: _note,
          )),
  _t('vid_audio_convert', 'تحويل صيغة الصوت', 'Audio Converter',
      ['تحويل الصوت', 'صيغة', 'mp3', 'wav', 'm4a', 'ogg', 'flac', 'opus', 'audio converter', 'convert'],
      Icons.transform,
      (_) => const MediaToolPage(
            title: 'تحويل صيغة الصوت',
            actionLabel: 'تحويل',
            pickLabel: 'اختيار ملف صوت',
            pickType: FileType.any,
            needAudio: true,
            build: _extract,
            options: [
              Opt.choice('fmt', 'الصيغة المطلوبة', audioFormats, initial: 'mp3'),
              _kbps,
            ],
            note: _note,
          )),
  _t('vid_audio_to_video', 'صوت إلى فيديو', 'Audio to Video',
      ['صوت الى فيديو', 'تحويل صوت لفيديو', 'ستوري', 'mp4', 'audio to video', 'mp3 to mp4'],
      Icons.video_library_outlined,
      (_) => const MediaToolPage(
            title: 'صوت إلى فيديو',
            actionLabel: 'إنشاء الفيديو',
            pickLabel: 'اختيار ملف صوت',
            pickType: FileType.audio,
            needAudio: true,
            build: _audioToVideo,
            options: [
              Opt.choice('size', 'شكل الفيديو',
                  [('720x720', 'مربع'), ('720x1280', 'طولي'), ('1280x720', 'عرضي')],
                  initial: '720x720'),
              Opt.choice('bg', 'لون الخلفية',
                  [('black', 'أسود'), ('navy', 'أزرق داكن'), ('darkgreen', 'أخضر داكن')],
                  initial: 'black'),
            ],
            note: 'ينتج فيديو بخلفية ملونة ثابتة مع الصوت. $_note',
          )),
  _t('vid_trim', 'قص الفيديو والصوت', 'Trim Video / Audio',
      ['قص', 'قطع', 'اقتطاع', 'مقطع', 'trim', 'cut', 'clip', 'video', 'audio'],
      Icons.content_cut,
      (_) => const MediaToolPage(
            title: 'قص الفيديو والصوت',
            actionLabel: 'قص',
            pickLabel: 'اختيار فيديو أو صوت',
            pickType: FileType.any,
            build: _trim,
            trimPicker: true,
            options: [
              Opt.toggle('precise', 'قص دقيق (أبطأ، ويعيد ترميز الفيديو)'),
            ],
            note:
                'حرّك بداية الشريط ونهايته لتحديد المقطع، واستخدم الأزرار الصغيرة للضبط الدقيق (ثانية أو عُشر ثانية). '
                'الوضع السريع يقص بدون إعادة ترميز وبدون خسارة جودة، لكن بداية الفيديو قد تتقدم قليلًا إلى أقرب إطار رئيسي. '
                'فعّل القص الدقيق إذا احتجت اللحظة بالضبط.',
          )),
  _t('vid_text', 'كتابة نص على الفيديو', 'Add Text to Video',
      ['كتابة', 'نص', 'عنوان', 'ترجمة', 'تعليق', 'نص على فيديو', 'text', 'caption', 'title', 'overlay'],
      Icons.title,
      (_) => const MediaToolPage(
            title: 'كتابة نص على الفيديو',
            actionLabel: 'إضافة النص',
            pickLabel: 'اختيار فيديو',
            pickType: FileType.video,
            needVideo: true,
            build: _text,
            options: [
              Opt.text('text', 'النص', hint: 'يدعم العربية'),
              Opt.choice('pos', 'المكان',
                  [('top', 'أعلى'), ('middle', 'وسط'), ('bottom', 'أسفل')],
                  initial: 'bottom'),
              Opt.choice('size', 'الحجم',
                  [('small', 'صغير'), ('medium', 'متوسط'), ('large', 'كبير')],
                  initial: 'medium'),
              Opt.choice('color', 'اللون',
                  [('white', 'أبيض'), ('yellow', 'أصفر'), ('black', 'أسود')],
                  initial: 'white'),
              Opt.toggle('box', 'خلفية خلف النص', on: true),
              Opt.text('from', 'يظهر من (اختياري)', hint: 'مثال 0:05'),
              Opt.text('to', 'يختفي عند (اختياري)', hint: 'مثال 0:15'),
            ],
            note: 'يظهر النص ثابتًا في المكان الذي تختاره. اترك الوقتين فارغين ليظهر طوال الفيديو. $_note',
          )),
  _t('vid_convert', 'تحويل صيغة الفيديو', 'Video Converter',
      ['تحويل الفيديو', 'صيغة', 'mp4', 'mkv', 'webm', 'avi', 'gif', 'video converter', 'convert'],
      Icons.sync_alt,
      (_) => const MediaToolPage(
            title: 'تحويل صيغة الفيديو',
            actionLabel: 'تحويل',
            pickLabel: 'اختيار فيديو',
            pickType: FileType.video,
            needVideo: true,
            build: _convert,
            options: [
              Opt.choice('fmt', 'الصيغة المطلوبة', videoFormats, initial: 'mp4'),
              Opt.choice('q', 'الجودة',
                  [('2', 'عالية'), ('5', 'متوسطة'), ('9', 'أقل حجمًا')],
                  initial: '5'),
            ],
            note: 'WEBM أبطأ في الترميز على الجوال. GIF يخرج بدون صوت وبعرض 480 بكسل. $_note',
          )),
  _t('vid_compress', 'ضغط الفيديو', 'Compress Video',
      ['ضغط', 'تصغير حجم', 'تقليل حجم', 'حجم الفيديو', 'compress', 'reduce', 'shrink'],
      Icons.compress,
      (_) => const MediaToolPage(
            title: 'ضغط الفيديو',
            actionLabel: 'ضغط',
            pickLabel: 'اختيار فيديو',
            pickType: FileType.video,
            needVideo: true,
            build: _compress,
            options: [
              Opt.choice('h', 'أقصى ارتفاع',
                  [('720', '720p'), ('480', '480p'), ('360', '360p')],
                  initial: '720'),
              Opt.choice('q', 'الجودة',
                  [('4', 'جيدة'), ('7', 'متوسطة'), ('11', 'أصغر حجم')],
                  initial: '7'),
            ],
            note:
                'يصغّر الدقة ويعيد الترميز. إذا كان الناتج أكبر من الأصلي لا يُحفظ. $_note',
          )),
  _t('vid_mute', 'إزالة الصوت من الفيديو', 'Mute Video',
      ['كتم', 'إزالة الصوت', 'بدون صوت', 'حذف الصوت', 'mute', 'remove audio', 'silent'],
      Icons.volume_off_outlined,
      (_) => const MediaToolPage(
            title: 'إزالة الصوت من الفيديو',
            actionLabel: 'إزالة الصوت',
            pickLabel: 'اختيار فيديو',
            pickType: FileType.video,
            needVideo: true,
            build: _mute,
            note: 'سريع وبدون خسارة جودة لأن الفيديو يُنسخ كما هو.',
          )),
];
