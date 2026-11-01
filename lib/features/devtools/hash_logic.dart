/// SHA-1 و SHA-256 بدون أي مكتبة خارجية (تعمل على أندرويد والويب والآيفون).
library;

import 'dart:typed_data';

const _m = 0xFFFFFFFF;

const _k256 = <int>[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

const _h256 = <int>[
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & _m;
int _rotl(int x, int n) => ((x << n) | (x >>> (32 - n))) & _m;

/// يضيف حشو الرسالة (بت 1 ثم أصفار ثم الطول بالبت في 8 بايتات).
Uint8List _pad(List<int> d) {
  final len = d.length;
  final total = ((len + 9 + 63) ~/ 64) * 64;
  final out = Uint8List(total);
  out.setRange(0, len, d);
  out[len] = 0x80;
  final bits = len * 8;
  final hi = bits ~/ 0x100000000;
  final lo = bits % 0x100000000;
  for (var i = 0; i < 4; i++) {
    out[total - 8 + i] = (hi >>> (24 - 8 * i)) & 0xFF;
    out[total - 4 + i] = (lo >>> (24 - 8 * i)) & 0xFF;
  }
  return out;
}

int _word(Uint8List m, int o) =>
    ((m[o] << 24) | (m[o + 1] << 16) | (m[o + 2] << 8) | m[o + 3]) & _m;

String _hex(List<int> h) =>
    [for (final x in h) x.toRadixString(16).padLeft(8, '0')].join();

String sha256Hex(List<int> data) {
  final m = _pad(data);
  final h = List<int>.of(_h256);
  final w = List<int>.filled(64, 0);
  for (var o = 0; o < m.length; o += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] = _word(m, o + 4 * i);
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _m;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & _m) & g);
      final t1 = (hh + s1 + ch + _k256[i] + w[i]) & _m;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final mj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + mj) & _m;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & _m;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & _m;
    }
    h[0] = (h[0] + a) & _m;
    h[1] = (h[1] + b) & _m;
    h[2] = (h[2] + c) & _m;
    h[3] = (h[3] + d) & _m;
    h[4] = (h[4] + e) & _m;
    h[5] = (h[5] + f) & _m;
    h[6] = (h[6] + g) & _m;
    h[7] = (h[7] + hh) & _m;
  }
  return _hex(h);
}

String sha1Hex(List<int> data) {
  final m = _pad(data);
  final h = <int>[0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0];
  final w = List<int>.filled(80, 0);
  for (var o = 0; o < m.length; o += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] = _word(m, o + 4 * i);
    }
    for (var i = 16; i < 80; i++) {
      w[i] = _rotl(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
    }
    var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4];
    for (var i = 0; i < 80; i++) {
      int f, k;
      if (i < 20) {
        f = (b & c) | ((~b & _m) & d);
        k = 0x5A827999;
      } else if (i < 40) {
        f = b ^ c ^ d;
        k = 0x6ED9EBA1;
      } else if (i < 60) {
        f = (b & c) | (b & d) | (c & d);
        k = 0x8F1BBCDC;
      } else {
        f = b ^ c ^ d;
        k = 0xCA62C1D6;
      }
      final t = (_rotl(a, 5) + f + e + k + w[i]) & _m;
      e = d;
      d = c;
      c = _rotl(b, 30);
      b = a;
      a = t;
    }
    h[0] = (h[0] + a) & _m;
    h[1] = (h[1] + b) & _m;
    h[2] = (h[2] + c) & _m;
    h[3] = (h[3] + d) & _m;
    h[4] = (h[4] + e) & _m;
  }
  return _hex(h);
}
