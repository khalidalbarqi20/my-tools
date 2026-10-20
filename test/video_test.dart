import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/video/video_logic.dart';

void main() {
  test('parseClock', () {
    expect(parseClock('90'), 90);
    expect(parseClock('1:30'), 90);
    expect(parseClock('1:02:03.5'), 3723.5);
    expect(parseClock('١:٣٠'), 90);
    expect(parseClock(''), isNull);
    expect(parseClock('abc'), isNull);
    expect(parseClock('-5'), isNull);
    expect(parseClock('1:2:3:4'), isNull);
  });
  test('fmtClock', () {
    expect(fmtClock(65), '1:05');
    expect(fmtClock(3723), '1:02:03');
    expect(fmtClock(0), '0:00');
  });
  test('rotationOf', () {
    expect(rotationOf(null), 0);
    expect(rotationOf({'tags': {'rotate': '90'}}), 90);
    expect(rotationOf({'side_data_list': [{'rotation': -90}]}), -90);
    expect(swapsDims(90), isTrue);
    expect(swapsDims(-90), isTrue);
    expect(swapsDims(270), isTrue);
    expect(swapsDims(180), isFalse);
    expect(swapsDims(0), isFalse);
  });
  test('audio args', () {
    final f = audioFmt('mp3', 192);
    expect(f.ext, 'mp3');
    final a = extractAudioArgs('in.mp4', 'out.mp3', f);
    expect(a, containsAllInOrder(['-vn', '-c:a', 'libmp3lame', '-b:a', '192k']));
    expect(a.last, 'out.mp3');
    expect(audioFmt('wav', 192).codec, ['-c:a', 'pcm_s16le']);
    expect(audioFmt('xyz', 128).ext, 'mp3');
  });
  test('trim args', () {
    final a = trimArgs('in.mp4', 'o.mp4', start: 10, end: 25.5);
    expect(a, containsAllInOrder(['-ss', '10.000', '-i', 'in.mp4', '-t', '15.500', '-c', 'copy']));
    final b = trimArgs('in.mp4', 'o.mp4', start: 0, precise: true);
    expect(b.contains('-t'), isFalse);
    expect(b, contains('mpeg4'));
    expect(trimExt('a.MKV', precise: false, audioOnly: false), 'mkv');
    expect(trimExt('a.xyz', precise: false, audioOnly: true), 'm4a');
    expect(trimExt('a.mkv', precise: true, audioOnly: false), 'mp4');
  });
  test('convert / compress / overlay args', () {
    expect(convertVideoArgs('i', 'o.webm', 'webm', '5'), contains('libvpx'));
    expect(convertVideoArgs('i', 'o.gif', 'gif', '5'), contains('-an'));
    expect(compressArgs('i', 'o', 720, '7')[compressArgs('i', 'o', 720, '7').indexOf('-vf') + 1],
        'scale=-2:min(ih\\,720)');
    final o = overlayArgs('v', 'p.png', 'o', start: 2, end: 5);
    expect(o[o.indexOf('-filter_complex') + 1], contains("enable='between(t,2.000,5.000)'"));
    expect(overlayArgs('v', 'p.png', 'o')[6].contains('enable'), isFalse);
    expect(videoMime('mkv'), 'video/x-matroska');
  });
}
