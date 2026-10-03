import 'package:qr/qr.dart';

enum QrKind { url, wifi, email, phone, sms, contact, text }

class QrParsed {
  final QrKind kind;
  final String raw;
  final List<(String, String)> rows;
  final Uri? openUri;
  final String copyText;
  final String copyLabel;
  QrParsed(this.kind, this.raw, this.rows,
      {this.openUri, String? copyText, this.copyLabel = 'نسخ'})
      : copyText = copyText ?? raw;

  String? get openLabel => openUri == null
      ? null
      : switch (kind) {
          QrKind.url => 'فتح',
          QrKind.email => 'إرسال',
          QrKind.sms => 'إرسال',
          _ => 'اتصال',
        };
}

String kindTitle(QrKind k) => switch (k) {
      QrKind.url => 'رابط',
      QrKind.wifi => 'شبكة Wi-Fi',
      QrKind.email => 'بريد إلكتروني',
      QrKind.phone => 'رقم هاتف',
      QrKind.sms => 'رسالة SMS',
      QrKind.contact => 'جهة اتصال',
      QrKind.text => 'نص',
    };

// ---------- أدوات مساعدة ----------

List<String> _splitUnescaped(String s, String sep) {
  final out = <String>[];
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == '\\' && i + 1 < s.length) {
      b.write(c);
      b.write(s[i + 1]);
      i++;
    } else if (c == sep) {
      out.add(b.toString());
      b.clear();
    } else {
      b.write(c);
    }
  }
  out.add(b.toString());
  return out;
}

String _unescape(String s) =>
    s.replaceAllMapped(RegExp(r'\\(.)'), (m) => m[1]!);

String _unescapeV(String s) => s
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\N', '\n')
    .replaceAll(r'\,', ',')
    .replaceAll(r'\;', ';')
    .replaceAll(r'\\', '\\');

String _dec(String s, {bool plus = true}) {
  try {
    return Uri.decodeComponent(plus ? s.replaceAll('+', ' ') : s);
  } catch (_) {
    return s;
  }
}

String _latinDigits(String s) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var t = s;
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ar[i], '$i');
  }
  return t;
}

Uri? _webUrl(String s) {
  if (s.isEmpty || RegExp(r'\s').hasMatch(s)) return null;
  final low = s.toLowerCase();
  String t;
  if (low.startsWith('http://') || low.startsWith('https://')) {
    t = s;
  } else if (low.startsWith('www.')) {
    t = 'https://$s';
  } else {
    return null;
  }
  final u = Uri.tryParse(t);
  if (u == null || u.host.isEmpty) return null;
  return u;
}

// ---------- التحليل ----------

QrParsed parseQr(String input) {
  final raw = input.trim();
  final low = raw.toLowerCase();
  if (low.startsWith('wifi:')) return _wifi(raw);
  if (low.startsWith('begin:vcard')) return _vcard(raw);
  if (low.startsWith('mecard:')) return _mecard(raw);
  if (low.startsWith('mailto:') || low.startsWith('matmsg:')) return _email(raw);
  if (low.startsWith('tel:')) {
    final n = raw.substring(4).replaceAll(RegExp(r'\s'), '');
    return QrParsed(QrKind.phone, raw, [('الرقم', n)],
        openUri: n.isEmpty ? null : Uri(scheme: 'tel', path: n), copyText: n);
  }
  if (low.startsWith('sms:') || low.startsWith('smsto:')) return _sms(raw);
  final url = _webUrl(raw);
  if (url != null) {
    return QrParsed(QrKind.url, raw, [('الرابط', raw)], openUri: url);
  }
  return QrParsed(QrKind.text, raw, [('النص', raw)]);
}

QrParsed _wifi(String raw) {
  final f = <String, String>{};
  for (final part in _splitUnescaped(raw.substring(5), ';')) {
    final i = part.indexOf(':');
    if (i <= 0) continue;
    f[part.substring(0, i).toUpperCase()] = _unescape(part.substring(i + 1));
  }
  final ssid = f['S'] ?? '';
  final pass = f['P'] ?? '';
  final t = (f['T'] ?? '').toUpperCase();
  final sec = (t.isEmpty || t == 'NOPASS')
      ? 'بدون كلمة مرور'
      : (t == 'WEP' ? 'WEP' : 'WPA/WPA2');
  return QrParsed(
    QrKind.wifi,
    raw,
    [
      ('اسم الشبكة', ssid),
      ('الأمان', sec),
      if (pass.isNotEmpty) ('كلمة المرور', pass),
      if ((f['H'] ?? '').toLowerCase() == 'true') ('مخفية', 'نعم'),
    ],
    copyText: pass.isNotEmpty ? pass : ssid,
    copyLabel: pass.isNotEmpty ? 'نسخ كلمة المرور' : 'نسخ',
  );
}

QrParsed _email(String raw) {
  var to = '', subject = '', body = '';
  if (raw.toLowerCase().startsWith('matmsg:')) {
    for (final part in _splitUnescaped(raw.substring(7), ';')) {
      final i = part.indexOf(':');
      if (i <= 0) continue;
      final k = part.substring(0, i).toUpperCase();
      final v = _unescape(part.substring(i + 1));
      if (k == 'TO') {
        to = v;
      } else if (k == 'SUB') {
        subject = v;
      } else if (k == 'BODY') {
        body = v;
      }
    }
  } else {
    final rest = raw.substring(7);
    final q = rest.indexOf('?');
    to = _dec(q < 0 ? rest : rest.substring(0, q), plus: false);
    if (q >= 0) {
      for (final kv in rest.substring(q + 1).split('&')) {
        final e = kv.indexOf('=');
        if (e <= 0) continue;
        final k = kv.substring(0, e).toLowerCase();
        final v = _dec(kv.substring(e + 1));
        if (k == 'subject') {
          subject = v;
        } else if (k == 'body') {
          body = v;
        }
      }
    }
  }
  final params = [
    if (subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
    if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
  ];
  return QrParsed(
    QrKind.email,
    raw,
    [
      ('العنوان', to),
      if (subject.isNotEmpty) ('الموضوع', subject),
      if (body.isNotEmpty) ('الرسالة', body),
    ],
    openUri: to.isEmpty
        ? null
        : Uri(
            scheme: 'mailto',
            path: to,
            query: params.isEmpty ? null : params.join('&')),
    copyText: to.isEmpty ? raw : to,
  );
}

QrParsed _sms(String raw) {
  final rest = raw.substring(raw.toLowerCase().startsWith('smsto:') ? 6 : 4);
  var number = '', body = '';
  final q = rest.indexOf('?');
  if (q >= 0) {
    number = rest.substring(0, q);
    for (final kv in rest.substring(q + 1).split('&')) {
      final e = kv.indexOf('=');
      if (e <= 0) continue;
      if (kv.substring(0, e).toLowerCase() == 'body') {
        body = _dec(kv.substring(e + 1));
      }
    }
  } else {
    final c = rest.indexOf(':');
    if (c >= 0) {
      number = rest.substring(0, c);
      body = rest.substring(c + 1);
    } else {
      number = rest;
    }
  }
  number = number.replaceAll(RegExp(r'\s'), '');
  return QrParsed(
    QrKind.sms,
    raw,
    [('الرقم', number), if (body.isNotEmpty) ('الرسالة', body)],
    openUri: number.isEmpty
        ? null
        : Uri(
            scheme: 'sms',
            path: number,
            query: body.isEmpty ? null : 'body=${Uri.encodeComponent(body)}'),
    copyText: number.isEmpty ? raw : number,
  );
}

QrParsed _contact(String raw, String name, String org, List<String> phones,
    List<String> emails) {
  final firstPhone =
      phones.isEmpty ? '' : phones.first.replaceAll(RegExp(r'\s'), '');
  return QrParsed(
    QrKind.contact,
    raw,
    [
      if (name.isNotEmpty) ('الاسم', name),
      for (final p in phones) ('الهاتف', p),
      for (final e in emails) ('البريد', e),
      if (org.isNotEmpty) ('الجهة', org),
    ],
    openUri: firstPhone.isEmpty ? null : Uri(scheme: 'tel', path: firstPhone),
    copyText: phones.isNotEmpty ? phones.first : raw,
    copyLabel: phones.isNotEmpty ? 'نسخ الرقم' : 'نسخ',
  );
}

QrParsed _vcard(String raw) {
  var name = '', org = '';
  final phones = <String>[], emails = <String>[];
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    final i = line.indexOf(':');
    if (i <= 0) continue;
    final key = line.substring(0, i).split(';').first.toUpperCase();
    final rawV = line.substring(i + 1).trim();
    final v = _unescapeV(rawV);
    if (v.isEmpty) continue;
    if (key == 'FN') {
      name = v;
    } else if (key == 'N') {
      if (name.isEmpty) {
        name = rawV
            .split(';')
            .map(_unescapeV)
            .where((p) => p.isNotEmpty)
            .toList()
            .reversed
            .join(' ');
      }
    } else if (key == 'TEL') {
      phones.add(v);
    } else if (key == 'EMAIL') {
      emails.add(v);
    } else if (key == 'ORG') {
      org = v.replaceAll(';', ' ').trim();
    }
  }
  return _contact(raw, name, org, phones, emails);
}

QrParsed _mecard(String raw) {
  var name = '', org = '';
  final phones = <String>[], emails = <String>[];
  for (final part in _splitUnescaped(raw.substring(7), ';')) {
    final i = part.indexOf(':');
    if (i <= 0) continue;
    final k = part.substring(0, i).toUpperCase();
    final v = _unescape(part.substring(i + 1));
    if (v.isEmpty) continue;
    if (k == 'N') {
      name = v.split(',').where((p) => p.isNotEmpty).toList().reversed.join(' ');
    } else if (k == 'TEL') {
      phones.add(v);
    } else if (k == 'EMAIL') {
      emails.add(v);
    } else if (k == 'ORG') {
      org = v;
    }
  }
  return _contact(raw, name, org, phones, emails);
}

// ---------- البناء (للمولد) ----------

String _esc(String s) =>
    s.replaceAllMapped(RegExp(r'[\\;,:"]'), (m) => '\\${m[0]}');

String _escV(String s) => s
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll('\n', '\\n');

String _phoneDigits(String s) {
  final t = _latinDigits(s.trim());
  final digits = t.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 3) throw const FormatException('اكتب رقم هاتف صحيحًا');
  return '${t.startsWith('+') ? '+' : ''}$digits';
}

String normalizeUrl(String s) {
  final t = s.trim();
  if (t.isEmpty) throw const FormatException('اكتب الرابط');
  return t.contains('://') ? t : 'https://$t';
}

String buildWifi(
    {required String ssid,
    String pass = '',
    String sec = 'WPA',
    bool hidden = false}) {
  if (ssid.trim().isEmpty) throw const FormatException('اكتب اسم الشبكة');
  final b = StringBuffer('WIFI:T:${sec == 'nopass' ? 'nopass' : sec};');
  b.write('S:${_esc(ssid)};');
  if (sec != 'nopass' && pass.isNotEmpty) b.write('P:${_esc(pass)};');
  if (hidden) b.write('H:true;');
  b.write(';');
  return b.toString();
}

String buildPhone(String n) => 'tel:${_phoneDigits(n)}';

String buildSms(String n, {String body = ''}) =>
    'SMSTO:${_phoneDigits(n)}:${body.trim()}';

String buildEmail(String to, {String subject = '', String body = ''}) {
  final a = to.trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(a)) {
    throw const FormatException('اكتب بريدًا إلكترونيًا صحيحًا');
  }
  final q = [
    if (subject.trim().isNotEmpty)
      'subject=${Uri.encodeComponent(subject.trim())}',
    if (body.trim().isNotEmpty) 'body=${Uri.encodeComponent(body.trim())}',
  ];
  return 'mailto:$a${q.isEmpty ? '' : '?${q.join('&')}'}';
}

String buildContact(
    {required String name,
    String phone = '',
    String email = '',
    String org = ''}) {
  if (name.trim().isEmpty) throw const FormatException('اكتب اسم جهة الاتصال');
  final lines = [
    'BEGIN:VCARD',
    'VERSION:3.0',
    'FN:${_escV(name.trim())}',
    'N:${_escV(name.trim())};;;;',
    if (phone.trim().isNotEmpty) 'TEL:${_phoneDigits(phone)}',
    if (email.trim().isNotEmpty) 'EMAIL:${_escV(email.trim())}',
    if (org.trim().isNotEmpty) 'ORG:${_escV(org.trim())}',
    'END:VCARD',
  ];
  return lines.join('\n');
}

/// يرجع null إذا كانت البيانات أطول من سعة QR.
QrImage? makeQr(String data, {int level = QrErrorCorrectLevel.M}) {
  if (data.isEmpty) return null;
  for (var v = 1; v <= 40; v++) {
    try {
      return QrImage(QrCode(v, level)..addData(data));
    } catch (_) {
      // جرّب إصدارًا أكبر
    }
  }
  return null;
}
