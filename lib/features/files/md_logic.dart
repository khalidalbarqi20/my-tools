/// محلل Markdown مبسّط (عناوين، فقرات، قوائم، اقتباس، كود، خط فاصل، وخط عريض/مائل/كود/رابط داخل السطر).
library;

enum MdKind { heading, paragraph, code, bullet, numbered, quote, rule }

class MdBlock {
  final MdKind kind;
  final String text;
  final int level;
  final int number;
  const MdBlock(this.kind, this.text, {this.level = 0, this.number = 0});
}

class MdSpan {
  final String text;
  final bool bold, italic, code;
  final String? link;
  const MdSpan(this.text, {this.bold = false, this.italic = false, this.code = false, this.link});
}

List<MdBlock> parseMarkdown(String src) {
  final lines = src.replaceAll('\r\n', '\n').split('\n');
  final out = <MdBlock>[];
  final para = <String>[];
  void flush() {
    if (para.isNotEmpty) {
      out.add(MdBlock(MdKind.paragraph, para.join(' ')));
      para.clear();
    }
  }

  var i = 0;
  while (i < lines.length) {
    final l = lines[i];
    final t = l.trim();
    if (t.startsWith('```')) {
      flush();
      final buf = <String>[];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        buf.add(lines[i]);
        i++;
      }
      out.add(MdBlock(MdKind.code, buf.join('\n')));
      i++;
      continue;
    }
    final h = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(t);
    if (h != null) {
      flush();
      out.add(MdBlock(MdKind.heading, h.group(2)!.replaceAll(RegExp(r'\s#+$'), ''), level: h.group(1)!.length));
    } else if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(t)) {
      flush();
      out.add(const MdBlock(MdKind.rule, ''));
    } else if (RegExp(r'^[-*+]\s+').hasMatch(t)) {
      flush();
      out.add(MdBlock(MdKind.bullet, t.replaceFirst(RegExp(r'^[-*+]\s+'), '')));
    } else if (RegExp(r'^\d+[.)]\s+').hasMatch(t)) {
      flush();
      final m = RegExp(r'^(\d+)[.)]\s+(.*)$').firstMatch(t)!;
      out.add(MdBlock(MdKind.numbered, m.group(2)!, number: int.parse(m.group(1)!)));
    } else if (t.startsWith('>')) {
      flush();
      out.add(MdBlock(MdKind.quote, t.replaceFirst(RegExp(r'^>\s?'), '')));
    } else if (t.isEmpty) {
      flush();
    } else {
      para.add(t);
    }
    i++;
  }
  flush();
  return out;
}

final _inline = RegExp(r'(\*\*(.+?)\*\*|__(.+?)__|`([^`]+)`|\[([^\]]+)\]\(([^)]+)\)|\*([^*]+)\*|_([^_]+)_)');

List<MdSpan> parseInline(String s) {
  final out = <MdSpan>[];
  var last = 0;
  for (final m in _inline.allMatches(s)) {
    if (m.start > last) out.add(MdSpan(s.substring(last, m.start)));
    if (m.group(2) != null) {
      out.add(MdSpan(m.group(2)!, bold: true));
    } else if (m.group(3) != null) {
      out.add(MdSpan(m.group(3)!, bold: true));
    } else if (m.group(4) != null) {
      out.add(MdSpan(m.group(4)!, code: true));
    } else if (m.group(5) != null) {
      out.add(MdSpan(m.group(5)!, link: m.group(6)));
    } else if (m.group(7) != null) {
      out.add(MdSpan(m.group(7)!, italic: true));
    } else {
      out.add(MdSpan(m.group(8)!, italic: true));
    }
    last = m.end;
  }
  if (last < s.length) out.add(MdSpan(s.substring(last)));
  return out;
}
