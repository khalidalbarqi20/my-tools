import '../extras/extras_logic.dart' show toWesternDigits;

/// معلومات الملف الإعلامي (مدة، صوت، فيديو، أبعاد الفيديو بعد تطبيق التدوير).
class ProbeInfo {
  final double? duration;
  final bool hasAudio, hasVideo;
  final int? width, height;
  const ProbeInfo(
      {this.duration,
      this.hasAudio = false,
      this.hasVideo = false,
      this.width,
      this.height});
}

/// مهمة FFmpeg جاهزة: الأوامر، ملف الناتج المؤقت، والاسم المقترح عند الحفظ.
class Job {
  final List<String> args;
  final String outPath, mime, name;
  final List<String> temps;
  final double? totalSec;
  final bool mustShrink;
  const Job(this.args, this.outPath, this.mime,
      {required this.name,
      this.temps = const [],
      this.totalSec,
      this.mustShrink = false});
}

/// "90" أو "1:30" أو "1:02:03.5" (يقبل الأرقام العربية) -> ثواني. null إذا غير صالح.
double? parseClock(String s) {
  final t = toWesternDigits(s).trim().replaceAll('٫', '.').replaceAll('،', '.');
  if (t.isEmpty) return null;
  final parts = t.split(':');
  if (parts.length > 3) return null;
  var total = 0.0;
  for (final p in parts) {
    final v = double.tryParse(p.trim());
    if (v == null || v < 0 || v.isNaN || v.isInfinite) return null;
    total = total * 60 + v;
  }
  return total;
}

String fmtClock(double sec) {
  final s = sec.round();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, r = s % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(r)}' : '$m:${two(r)}';
}

/// مثل fmtClock مع عُشر الثانية: 1:05.3
String fmtClockMs(double sec) {
  final t = (sec * 10).round();
  return '${fmtClock((t ~/ 10).toDouble())}.${t % 10}';
}

/// زاوية تدوير الفيديو من خصائص ffprobe (وسم rotate أو displaymatrix).
int rotationOf(Map? p) {
  if (p == null) return 0;
  final tags = p['tags'];
  if (tags is Map && tags['rotate'] != null) {
    final v = num.tryParse('${tags['rotate']}');
    if (v != null) return v.round();
  }
  final sd = p['side_data_list'];
  if (sd is List) {
    for (final e in sd) {
      if (e is Map && e['rotation'] != null) {
        final v = num.tryParse('${e['rotation']}');
        if (v != null) return v.round();
      }
    }
  }
  return 0;
}

bool swapsDims(int rotation) => rotation % 180 == 90;

class AudioFmt {
  final String ext, mime;
  final List<String> codec;
  const AudioFmt(this.ext, this.mime, this.codec);
}

const audioFormats = [
  ('mp3', 'MP3'),
  ('m4a', 'M4A (AAC)'),
  ('wav', 'WAV'),
  ('ogg', 'OGG'),
  ('opus', 'OPUS'),
  ('flac', 'FLAC'),
];

AudioFmt audioFmt(String key, int kbps) {
  final b = '${kbps}k';
  switch (key) {
    case 'm4a':
      return AudioFmt('m4a', 'audio/mp4', ['-c:a', 'aac', '-b:a', b]);
    case 'wav':
      return const AudioFmt('wav', 'audio/wav', ['-c:a', 'pcm_s16le']);
    case 'ogg':
      return AudioFmt('ogg', 'audio/ogg', ['-c:a', 'libvorbis', '-b:a', b]);
    case 'opus':
      return AudioFmt('opus', 'audio/opus', ['-c:a', 'libopus', '-b:a', b]);
    case 'flac':
      return const AudioFmt('flac', 'audio/flac', ['-c:a', 'flac']);
    default:
      return AudioFmt('mp3', 'audio/mpeg', ['-c:a', 'libmp3lame', '-b:a', b]);
  }
}

List<String> extractAudioArgs(String inp, String out, AudioFmt f) =>
    ['-y', '-i', inp, '-vn', '-map', '0:a:0', ...f.codec, out];

String _n(double v) => v.toStringAsFixed(3);

const _keepExts = {
  'mp4', 'mov', 'mkv', 'webm', '3gp', 'm4v', 'm4a', 'mp3', 'wav', 'ogg', 'flac', 'aac', 'opus'
};

/// امتداد ناتج القص: نفس امتداد الأصل عند النسخ المباشر، وmp4 عند إعادة الترميز.
String trimExt(String name, {required bool precise, required bool audioOnly}) {
  if (precise) return 'mp4';
  final i = name.lastIndexOf('.');
  final e = i > 0 ? name.substring(i + 1).toLowerCase() : '';
  if (_keepExts.contains(e)) return e;
  return audioOnly ? 'm4a' : 'mp4';
}

List<String> trimArgs(String inp, String out,
    {required double start, double? end, bool precise = false}) {
  return [
    '-y',
    '-ss', _n(start),
    '-i', inp,
    if (end != null) ...['-t', _n(end - start)],
    '-map', '0:v:0?',
    '-map', '0:a:0?',
    if (precise)
      ...['-c:v', 'mpeg4', '-q:v', '3', '-c:a', 'aac', '-b:a', '160k']
    else
      ...['-c', 'copy', '-avoid_negative_ts', 'make_zero'],
    out,
  ];
}

const videoFormats = [
  ('mp4', 'MP4'),
  ('mkv', 'MKV'),
  ('webm', 'WEBM'),
  ('avi', 'AVI'),
  ('gif', 'GIF'),
];

String videoMime(String ext) => switch (ext) {
      'mkv' => 'video/x-matroska',
      'webm' => 'video/webm',
      'avi' => 'video/x-msvideo',
      'gif' => 'image/gif',
      _ => 'video/mp4',
    };

/// q: قيمة -q:v لـ mpeg4 (الأقل = جودة أعلى). webm يستخدم معدل بت حسب q.
List<String> convertVideoArgs(String inp, String out, String fmt, String q) {
  final base = ['-y', '-i', inp];
  switch (fmt) {
    case 'webm':
      final br = q == '2' ? '2M' : (q == '5' ? '1M' : '500k');
      return [
        ...base,
        '-map', '0:v:0', '-map', '0:a:0?',
        '-c:v', 'libvpx', '-b:v', br, '-deadline', 'realtime', '-cpu-used', '5',
        '-c:a', 'libopus', '-b:a', '128k',
        out,
      ];
    case 'avi':
      return [
        ...base,
        '-map', '0:v:0', '-map', '0:a:0?',
        '-c:v', 'mpeg4', '-q:v', q, '-c:a', 'libmp3lame', '-b:a', '192k',
        out,
      ];
    case 'gif':
      return [
        ...base,
        '-an',
        '-vf',
        'fps=12,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse',
        '-loop', '0',
        out,
      ];
    default: // mp4, mkv
      return [
        ...base,
        '-map', '0:v:0', '-map', '0:a:0?',
        '-c:v', 'mpeg4', '-q:v', q, '-c:a', 'aac', '-b:a', '160k',
        out,
      ];
  }
}

List<String> compressArgs(String inp, String out, int maxHeight, String q) => [
      '-y', '-i', inp,
      '-map', '0:v:0', '-map', '0:a:0?',
      '-vf', 'scale=-2:min(ih\\,$maxHeight)',
      '-c:v', 'mpeg4', '-q:v', q,
      '-c:a', 'aac', '-b:a', '128k',
      out,
    ];

List<String> muteArgs(String inp, String out) =>
    ['-y', '-i', inp, '-map', '0:v:0', '-an', '-c:v', 'copy', out];

/// صوت إلى فيديو بخلفية ملونة ثابتة (مثال size: 720x720).
List<String> audioToVideoArgs(String audio, String out, String size, String bg) => [
      '-y',
      '-f', 'lavfi', '-i', 'color=c=$bg:s=$size:r=2',
      '-i', audio,
      '-map', '0:v', '-map', '1:a:0',
      '-c:v', 'mpeg4', '-q:v', '8', '-pix_fmt', 'yuv420p',
      '-c:a', 'aac', '-b:a', '192k',
      '-shortest',
      out,
    ];

/// يضع صورة النص (PNG بحجم الفيديو) فوق الفيديو، وبشكل اختياري بين زمنين.
List<String> overlayArgs(String video, String png, String out,
    {double? start, double? end}) {
  final en = (start != null || end != null)
      ? ":enable='between(t,${_n(start ?? 0)},${_n(end ?? 999999)})'"
      : '';
  return [
    '-y', '-i', video, '-i', png,
    '-filter_complex', '[0:v][1:v]overlay=0:0$en[v]',
    '-map', '[v]', '-map', '0:a:0?',
    '-c:v', 'mpeg4', '-q:v', '3',
    '-c:a', 'aac', '-b:a', '160k',
    out,
  ];
}
