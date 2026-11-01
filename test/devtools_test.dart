import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/devtools/dev_logic.dart';
import 'package:my_tools/features/devtools/hash_logic.dart';

String _b64u(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');

void main() {
  test('SHA-256 و SHA-1 بقيم معروفة', () {
    expect(sha256Hex(utf8.encode('')),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    expect(sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    expect(sha1Hex(utf8.encode('abc')), 'a9993e364706816aba3e25717850c26c9cd0d89d');
    expect(sha1Hex(utf8.encode('')), 'da39a3ee5e6b4b0d3255bfef95601890afd80709');
    // حدود الحشو: 55 و56 و64 بايت
    expect(sha256Hex(List.filled(56, 0x61)),
        'b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a');
    expect(sha1Hex(List.filled(64, 0x61)), '0098ba824b5c16427bd7a1122a5a442a25ec644d');
  });

  test('قوة كلمة المرور', () {
    expect(passwordReport('').level, 0);
    expect(passwordReport('password').level, 0);
    expect(passwordReport('123456').level, 0);
    expect(passwordReport('Xk9#mQ2\$vLp7!zRt').level, greaterThanOrEqualTo(3));
    expect(passwordReport('abc').tips, isNotEmpty);
  });

  test('رد HIBP', () {
    const body = '0018A45C4D1DEF81644B54AB7F969B88D65:3\r\n00D4F6E8FA6EECAD2A3AA415EEC418D38EC:2';
    expect(hibpCount(body, '00D4F6E8FA6EECAD2A3AA415EEC418D38EC'), 2);
    expect(hibpCount(body, 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'), 0);
  });

  test('فك JWT', () {
    final tok = '${_b64u('{"alg":"HS256","typ":"JWT"}')}.${_b64u('{"sub":"1","exp":1700000000,"iat":1600000000}')}.sig';
    final j = decodeJwt(tok);
    expect(j.header['alg'], 'HS256');
    expect(j.payload['sub'], '1');
    expect(j.exp, DateTime.utc(2023, 11, 14, 22, 13, 20));
    expect(() => decodeJwt('abc'), throwsFormatException);
    expect(() => decodeJwt('a.b.c'), throwsFormatException);
  });

  test('الطابع الزمني', () {
    expect(parseTimestamp('1700000000'), DateTime.utc(2023, 11, 14, 22, 13, 20));
    expect(parseTimestamp('1700000000000'), DateTime.utc(2023, 11, 14, 22, 13, 20));
    expect(parseTimestamp('abc'), isNull);
    expect(fmtDate(DateTime.utc(2024, 1, 2, 3, 4, 5)), '2024-01-02 03:04:05');
  });

  test('مقارنة نصين', () {
    final d = diffLines(['a', 'b', 'c'], ['a', 'x', 'c', 'd']);
    expect(d.where((e) => e.op == DiffOp.same).length, 2);
    expect(d.where((e) => e.op == DiffOp.del).map((e) => e.text), ['b']);
    expect(d.where((e) => e.op == DiffOp.add).map((e) => e.text), ['x', 'd']);
    expect(diffLines(['a'], ['a']).every((e) => e.op == DiffOp.same), true);
  });
}
