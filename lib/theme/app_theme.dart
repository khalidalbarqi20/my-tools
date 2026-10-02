import 'package:flutter/material.dart';

const _seed = Color(0xFF1E6F5C);

ThemeData _build(Brightness b) {
  final cs = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
  final r = BorderRadius.circular(14);
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    appBarTheme: const AppBarTheme(centerTitle: false, scrolledUnderElevation: 0),
    inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: r)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: r))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: r))),
  );
}

final lightTheme = _build(Brightness.light);
final darkTheme = _build(Brightness.dark);
