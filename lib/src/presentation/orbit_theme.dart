import 'package:flutter/material.dart';

class OrbitTheme {
  static const ink = Color(0xFF0B1016);
  static const panel = Color(0xFF111923);
  static const panelRaised = Color(0xFF182330);
  static const accent = Color(0xFF65D9C1);

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ).copyWith(
          surface: ink,
          surfaceContainerLowest: const Color(0xFF080C11),
          surfaceContainerLow: panel,
          surfaceContainer: panelRaised,
          surfaceContainerHigh: const Color(0xFF203040),
          primary: accent,
          onPrimary: const Color(0xFF06251F),
          secondary: const Color(0xFF9CB8CB),
          onSurface: const Color(0xFFE9F1F3),
          onSurfaceVariant: const Color(0xFFA6B4BE),
          outline: const Color(0xFF344655),
          outlineVariant: const Color(0xFF243542),
          error: const Color(0xFFFF8F92),
        );
    final base = ThemeData.dark(useMaterial3: true);
    final text = base.textTheme.apply(
      fontFamily: 'SF Pro Display',
      fontFamilyFallback: const ['Segoe UI', 'PingFang SC', 'Noto Sans SC'],
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        bodyMedium: text.bodyMedium?.copyWith(
          fontSize: 13,
          height: 1.45,
          letterSpacing: 0,
        ),
        labelMedium: text.labelMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 19),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surfaceContainerLow.withAlpha(225),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0C131B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        hintStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withAlpha(160),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF253543),
          borderRadius: BorderRadius.circular(7),
        ),
        textStyle: text.bodySmall?.copyWith(color: Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          side: BorderSide(color: scheme.outline),
        ),
      ),
    );
  }
}
