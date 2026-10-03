import 'package:flutter/material.dart';

class AppColors {
  final Color? accent, bg, icon;
  const AppColors({this.accent, this.bg, this.icon});
  AppColors withAccent(Color? c) => AppColors(accent: c, bg: bg, icon: icon);
  AppColors withBg(Color? c) => AppColors(accent: accent, bg: c, icon: icon);
  AppColors withIcon(Color? c) => AppColors(accent: accent, bg: bg, icon: c);
  bool get isDefault => accent == null && bg == null && icon == null;
}

/// يقبل "FF8800" أو "#FF8800"، ويرجع null إذا كان غير صالح.
Color? parseHex(String s) {
  final t = s.trim().replaceAll('#', '');
  if (t.length != 6) return null;
  final v = int.tryParse(t, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

String hexOf(Color c) =>
    c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
