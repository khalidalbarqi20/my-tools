import 'package:flutter/material.dart';
import 'app_colors.dart';

const _defaultSeed = Color(0xFF1E6F5C);
const _font = 'Tajawal';

class AppExtras extends ThemeExtension<AppExtras> {
  final Color card, border;
  final Color? icon;
  const AppExtras({required this.card, required this.border, this.icon});
  @override
  AppExtras copyWith({Color? card, Color? border, Color? icon}) => AppExtras(
      card: card ?? this.card,
      border: border ?? this.border,
      icon: icon ?? this.icon);
  @override
  AppExtras lerp(ThemeExtension<AppExtras>? other, double t) {
    if (other is! AppExtras) return this;
    return AppExtras(
        card: Color.lerp(card, other.card, t)!,
        border: Color.lerp(border, other.border, t)!,
        icon: Color.lerp(icon, other.icon, t));
  }
}

AppExtras _x(BuildContext c) =>
    Theme.of(c).extension<AppExtras>() ??
    const AppExtras(card: Colors.white, border: Color(0x1F000000));

Color cardColor(BuildContext c) => _x(c).card;
Color softBorder(BuildContext c) => _x(c).border;

const _catOrder = [
  'calc', 'convert', 'pdf', 'image', 'qr', 'time', 'text', 'device', 'random'
];

/// ألوان هادئة لكل قسم، أو لون موحد إذا اختار المستخدم لون الأيقونات.
({Color bg, Color fg, Color text}) tonalFor(BuildContext context, String cat) {
  final cs = Theme.of(context).colorScheme;
  final ic = _x(context).icon;
  if (ic != null) {
    return (bg: ic.withValues(alpha: 0.14), fg: ic, text: cs.onSurface);
  }
  switch (_catOrder.indexOf(cat) % 3) {
    case 0:
      return (
        bg: cs.primaryContainer,
        fg: cs.onPrimaryContainer,
        text: cs.onPrimaryContainer
      );
    case 1:
      return (
        bg: cs.secondaryContainer,
        fg: cs.onSecondaryContainer,
        text: cs.onSecondaryContainer
      );
    default:
      return (
        bg: cs.tertiaryContainer,
        fg: cs.onTertiaryContainer,
        text: cs.onTertiaryContainer
      );
  }
}

ThemeData buildTheme(Brightness mode, AppColors c) {
  // الخلفية المخصصة تحدد الوضع (فاتح/داكن) لضمان وضوح النصوص.
  final bright =
      c.bg == null ? mode : ThemeData.estimateBrightnessForColor(c.bg!);
  final cs = ColorScheme.fromSeed(
      seedColor: c.accent ?? _defaultSeed, brightness: bright);
  final dark = bright == Brightness.dark;
  final bg = c.bg ?? (dark ? cs.surface : const Color(0xFFF6F9F8));
  final Color card;
  if (c.bg == null) {
    card = dark ? cs.surfaceContainer : Colors.white;
  } else {
    card = dark ? Color.lerp(bg, Colors.white, 0.08)! : Colors.white;
  }
  final r14 = BorderRadius.circular(14);
  final r12 = BorderRadius.circular(12);
  OutlineInputBorder ob(Color col, [double w = 1]) => OutlineInputBorder(
      borderRadius: r14, borderSide: BorderSide(color: col, width: w));
  TextStyle ts(double s, FontWeight w) =>
      TextStyle(fontFamily: _font, fontSize: s, fontWeight: w);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    fontFamily: _font,
    scaffoldBackgroundColor: bg,
    iconTheme: c.icon == null ? null : IconThemeData(color: c.icon),
    extensions: [
      AppExtras(
          card: card,
          border: cs.outlineVariant.withValues(alpha: 0.6),
          icon: c.icon),
    ],
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
      fillColor: card,
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
        backgroundColor: card,
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
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: c.icon ??
              (s.contains(WidgetState.selected)
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant))),
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
      backgroundColor: card,
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
