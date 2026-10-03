import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/qr/qr_logic.dart';

void main() {
  test('الروابط', () {
    final p = parseQr('https://example.com/a?b=1');
    expect(p.kind, QrKind.url);
    expect(p.openUri.toString(), 'https://example.com/a?b=1');
    expect(parseQr('www.example.com').openUri.toString(), 'https://www.example.com');
    expect(parseQr('example.com').kind, QrKind.text);
    expect(parseQr('hello https://x.com').kind, QrKind.text);
    expect(parseQr('javascript:alert(1)').openUri, isNull);
    expect(parseQr('   ').kind, QrKind.text);
  });
  test('Wi-Fi', () {
    final p = parseQr('WIFI:T:WPA;S:Home;P:12345678;;');
    expect(p.kind, QrKind.wifi);
    expect(p.rows[0], ('اسم الشبكة', 'Home'));
    expect(p.rows[1], ('الأمان', 'WPA/WPA2'));
    expect(p.rows[2], ('كلمة المرور', '12345678'));
    expect(p.copyText, '12345678');
    final n = parseQr('WIFI:T:nopass;S:Cafe;;');
    expect(n.rows.length, 2);
    expect(n.rows[1].$2, 'بدون كلمة مرور');
    expect(n.copyText, 'Cafe');
  });
  test('Wi-Fi ذهاب وإياب مع رموز خاصة', () {
    const pass = 'pa:ss,w"d\\x;';
    final p = parseQr(buildWifi(ssid: 'My;Net', pass: pass, hidden: true));
    expect(p.rows[0].$2, 'My;Net');
    expect(p.copyText, pass);
    expect(p.rows.any((r) => r.$1 == 'مخفية'), true);
    expect(buildWifi(ssid: 'Cafe', sec: 'nopass'), 'WIFI:T:nopass;S:Cafe;;');
    expect(() => buildWifi(ssid: ' '), throwsFormatException);
  });
  test('الهاتف', () {
    final p = parseQr('tel:+966 50 123 4567');
    expect(p.kind, QrKind.phone);
    expect(p.rows[0].$2, '+966501234567');
    expect(p.openUri.toString(), 'tel:+966501234567');
    expect(buildPhone('٠٥٠١٢٣٤٥٦٧'), 'tel:0501234567');
    expect(buildPhone('+966 50-123-4567'), 'tel:+966501234567');
    expect(() => buildPhone('12'), throwsFormatException);
    expect(() => buildPhone('abc'), throwsFormatException);
  });
  test('البريد', () {
    final p = parseQr(buildEmail('a+b@x.com', subject: 'Hi there', body: 'x&y'));
    expect(p.kind, QrKind.email);
    expect(p.rows[0].$2, 'a+b@x.com');
    expect(p.rows[1].$2, 'Hi there');
    expect(p.rows[2].$2, 'x&y');
    expect(p.openUri!.scheme, 'mailto');
    final m = parseQr('MATMSG:TO:me@x.com;SUB:Hello;BODY:Body text;;');
    expect(m.rows[0].$2, 'me@x.com');
    expect(m.rows[1].$2, 'Hello');
    expect(() => buildEmail('not-an-email'), throwsFormatException);
  });
  test('SMS', () {
    final p = parseQr('SMSTO:+966501234567:hello there');
    expect(p.kind, QrKind.sms);
    expect(p.rows[0].$2, '+966501234567');
    expect(p.rows[1].$2, 'hello there');
    expect(p.openUri!.queryParameters['body'], 'hello there');
    final q = parseQr(buildSms('+966501234567', body: 'hi'));
    expect(q.rows[1].$2, 'hi');
    final s = parseQr('sms:+966501234567?body=Hi%20you');
    expect(s.rows[1].$2, 'Hi you');
  });
  test('جهات الاتصال', () {
    final p = parseQr(buildContact(
        name: 'Ali, Ahmed', phone: '+966501234567', email: 'a@x.com', org: 'Acme'));
    expect(p.kind, QrKind.contact);
    expect(p.rows.first, ('الاسم', 'Ali, Ahmed'));
    expect(p.openUri!.scheme, 'tel');
    expect(p.copyText, '+966501234567');
    final v = parseQr(
        'BEGIN:VCARD\nVERSION:3.0\nN:Doe;John;;;\nTEL;TYPE=CELL:+1 555 1234\nEMAIL:j@x.com\nORG:Acme\nEND:VCARD');
    expect(v.rows.first, ('الاسم', 'John Doe'));
    expect(v.openUri.toString(), 'tel:+15551234');
    final m = parseQr('MECARD:N:Doe,John;TEL:12345;EMAIL:j@x.com;;');
    expect(m.rows.first, ('الاسم', 'John Doe'));
    expect(() => buildContact(name: ''), throwsFormatException);
  });
  test('نص ورابط', () {
    expect(normalizeUrl('example.com'), 'https://example.com');
    expect(normalizeUrl('http://a.com'), 'http://a.com');
    expect(() => normalizeUrl(' '), throwsFormatException);
    expect(kindTitle(QrKind.wifi), 'شبكة Wi-Fi');
  });
  test('makeQr', () {
    final a = makeQr('hello')!;
    expect(a.moduleCount, 21);
    expect(a.isDark(0, 0), true);
    expect(makeQr('a' * 500)!.moduleCount > 21, true);
    expect(makeQr('مرحبا بالعالم')!.moduleCount >= 21, true);
    expect(makeQr('a' * 10000), isNull);
    expect(makeQr(''), isNull);
  });
}
