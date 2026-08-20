import 'package:flutter/material.dart';

class OrbitTheme {
  static const ink = Color(0xFFE7EEF3);
  static const panel = Color(0xFFF7FAFC);
  static const panelRaised = Color(0xFFFFFFFF);
  static const accent = Color(0xFF168B78);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ).copyWith(
          surface: ink,
          surfaceContainerLowest: const Color(0xFFDDE7ED),
          surfaceContainerLow: panel,
          surfaceContainer: panelRaised,
          surfaceContainerHigh: const Color(0xFFE8F0F4),
          surfaceContainerHighest: const Color(0xFFD9E4EA),
          primary: accent,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFCDEDE6),
          onPrimaryContainer: const Color(0xFF073D34),
          secondary: const Color(0xFF5D77A4),
          onSecondary: Colors.white,
          onSurface: const Color(0xFF1B2A34),
          onSurfaceVariant: const Color(0xFF60717D),
          outline: const Color(0xFF9AAEBA),
          outlineVariant: const Color(0xFFD1DEE5),
          error: const Color(0xFFB53D4B),
        );
    final base = ThemeData.light(useMaterial3: true);
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
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: text.bodyMedium?.copyWith(
          fontSize: 13,
          height: 1.45,
          letterSpacing: 0,
        ),
        labelMedium: text.labelMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
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
        color: scheme.surfaceContainerLow.withAlpha(235),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withAlpha(205),
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
          color: scheme.onSurfaceVariant.withAlpha(175),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF263A47),
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
