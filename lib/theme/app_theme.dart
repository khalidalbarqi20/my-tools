import 'package:flutter/material.dart';

const _seed = Color(0xFF1E6F5C);
const _font = 'Tajawal';

Color cardColor(BuildContext c) {
  final t = Theme.of(c);
  return t.brightness == Brightness.light
      ? Colors.white
      : t.colorScheme.surfaceContainer;
}

Color softBorder(BuildContext c) =>
    Theme.of(c).colorScheme.outlineVariant.withValues(alpha: 0.6);

const _catOrder = [
  'calc', 'convert', 'pdf', 'image', 'qr', 'time', 'text', 'device', 'random'
];

/// ألوان هادئة مشتقة من نفس اللون الأساسي لكل قسم.
({Color bg, Color fg}) tonalFor(BuildContext context, String cat) {
  final cs = Theme.of(context).colorScheme;
  switch (_catOrder.indexOf(cat) % 3) {
    case 0:
      return (bg: cs.primaryContainer, fg: cs.onPrimaryContainer);
    case 1:
      return (bg: cs.secondaryContainer, fg: cs.onSecondaryContainer);
    default:
      return (bg: cs.tertiaryContainer, fg: cs.onTertiaryContainer);
  }
}

ThemeData _build(Brightness b) {
  final cs = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
  final dark = b == Brightness.dark;
  final r14 = BorderRadius.circular(14);
  final r12 = BorderRadius.circular(12);
  final fill = dark ? cs.surfaceContainerHigh : Colors.white;
  final card = dark ? cs.surfaceContainer : Colors.white;
  OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: r14, borderSide: BorderSide(color: c, width: w));
  TextStyle ts(double s, FontWeight w) =>
      TextStyle(fontFamily: _font, fontSize: s, fontWeight: w);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    fontFamily: _font,
    scaffoldBackgroundColor: dark ? cs.surface : const Color(0xFFF6F9F8),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: cs.onSurface,
      titleTextStyle: ts(20, FontWeight.w700).copyWith(color: cs.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: ob(cs.outlineVariant),
      enabledBorder: ob(cs.outlineVariant),
      focusedBorder: ob(cs.primary, 1.8),
      errorBorder: ob(cs.error),
      focusedErrorBorder: ob(cs.error, 1.8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: r14),
        textStyle: ts(16, FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        backgroundColor: fill,
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: r14),
        textStyle: ts(15, FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: r12),
        textStyle: ts(15, FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: cs.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => ts(
          12,
          s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: r14),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: r12),
      side: BorderSide(color: cs.outlineVariant),
      backgroundColor: fill,
      labelStyle: ts(14, FontWeight.w600),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: r12)),
        textStyle: WidgetStatePropertyAll(ts(13, FontWeight.w600)),
      ),
    ),
    dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.5), thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
  );
}

final lightTheme = _build(Brightness.light);
final darkTheme = _build(Brightness.dark);
