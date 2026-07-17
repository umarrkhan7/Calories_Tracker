import 'package:flutter/material.dart';

// ── DARK COLORS (your exact current colors) ─────────────────────
class DarkColors {
  static const bg         = Color(0xFF0D0D0D);
  static const surface    = Color(0xFF1A1A1A);
  static const surfaceAlt = Color(0xFF222222);
  static const divider    = Color(0xFF2A2A2A);
  static const green      = Color(0xFF2ECC71);
  static const greenDim   = Color(0xFF1A3D2B);
  static const orange     = Color(0xFFF97316);
  static const orangeDim  = Color(0xFF3D2010);
  static const white      = Color(0xFFFFFFFF);
  static const subtext    = Color(0xFF9CA3AF);
  static const textHint   = Color(0xFF555555);
}

// ── LIGHT COLORS (white-based equivalent) ───────────────────────
class LightColors {
  static const bg         = Color(0xFFF5F5F5);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F0F0);
  static const divider    = Color(0xFFE5E5E5);
  static const green      = Color(0xFF22A85A);
  static const greenDim   = Color(0xFFDCF5E9);
  static const orange     = Color(0xFFF97316);
  static const orangeDim  = Color(0xFFFFEDE0);
  static const white      = Color(0xFF0D0D0D);
  static const subtext    = Color(0xFF6B7280);
  static const textHint   = Color(0xFFB0B0B0);
}
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  final Color bg, surface, surfaceAlt, divider;
  final Color green, greenDim, orange, orangeDim;
  final Color white, subtext, textHint;

  const AppColorExtension({
    required this.bg, required this.surface, required this.surfaceAlt,
    required this.divider, required this.green, required this.greenDim,
    required this.orange, required this.orangeDim, required this.white,
    required this.subtext, required this.textHint,
  });

  @override
  AppColorExtension copyWith({
    Color? bg, Color? surface, Color? surfaceAlt, Color? divider,
    Color? green, Color? greenDim, Color? orange, Color? orangeDim,
    Color? white, Color? subtext, Color? textHint,
  }) => AppColorExtension(
    bg: bg ?? this.bg, surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt, divider: divider ?? this.divider,
    green: green ?? this.green, greenDim: greenDim ?? this.greenDim,
    orange: orange ?? this.orange, orangeDim: orangeDim ?? this.orangeDim,
    white: white ?? this.white, subtext: subtext ?? this.subtext,
    textHint: textHint ?? this.textHint,
  );

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other == null) return this;
    return AppColorExtension(
      bg:         Color.lerp(bg, other.bg, t)!,
      surface:    Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      divider:    Color.lerp(divider, other.divider, t)!,
      green:      Color.lerp(green, other.green, t)!,
      greenDim:   Color.lerp(greenDim, other.greenDim, t)!,
      orange:     Color.lerp(orange, other.orange, t)!,
      orangeDim:  Color.lerp(orangeDim, other.orangeDim, t)!,
      white:      Color.lerp(white, other.white, t)!,
      subtext:    Color.lerp(subtext, other.subtext, t)!,
      textHint:   Color.lerp(textHint, other.textHint, t)!,
    );
  }
}

// shortcut
extension AppThemeX on BuildContext {
  AppColorExtension get c => Theme.of(this).extension<AppColorExtension>()!;
}

// ── THEME DATA ───────────────────────────────────────────────────
class AppTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DarkColors.bg,
    extensions: const [AppColorExtension(
      bg: DarkColors.bg, surface: DarkColors.surface, surfaceAlt: DarkColors.surfaceAlt,
      divider: DarkColors.divider, green: DarkColors.green, greenDim: DarkColors.greenDim,
      orange: DarkColors.orange, orangeDim: DarkColors.orangeDim, white: DarkColors.white,
      subtext: DarkColors.subtext, textHint: DarkColors.textHint,
    )],
  );

  static final light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: LightColors.bg,
    extensions: const [AppColorExtension(
      bg: LightColors.bg, surface: LightColors.surface, surfaceAlt: LightColors.surfaceAlt,
      divider: LightColors.divider, green: LightColors.green, greenDim: LightColors.greenDim,
      orange: LightColors.orange, orangeDim: LightColors.orangeDim, white: LightColors.white,
      subtext: LightColors.subtext, textHint: LightColors.textHint,
    )],
  );

}