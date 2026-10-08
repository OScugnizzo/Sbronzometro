import 'package:flutter/material.dart';

/// Centralised light/dark theming.
///
/// Both themes are generated from the same brand seed so the entire app -
/// including the animated splash screen - adapts automatically to the system
/// light/dark setting via `ThemeMode.system`.
abstract final class AppTheme {
  /// Brand accent used to seed the light colour scheme.
  static const Color brand = Color(0xFFE8590C);

  /// Slightly lighter accent that keeps good contrast on dark backgrounds.
  static const Color brandDark = Color(0xFFFF8A4C);

  static ThemeData light() => _build(Brightness.light, brand);

  static ThemeData dark() => _build(Brightness.dark, brandDark);

  static ThemeData _build(Brightness brightness, Color seed) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final ThemeData base = ThemeData(colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFFDF7F2)
          : const Color(0xFF14100F),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 10,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.15),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}
