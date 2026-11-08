import 'package:flutter/material.dart';

/// Тема как у LawMatic B2: Material 3 от синего семени, светлая и тёмная.
/// Своей палитры «Экоцентра» пока нет — цвет действий общий с линейкой.
abstract final class AppTheme {
  static const Color brandNavy = Color(0xFF003983);
  static const Color brandPrimaryDark = Color(0xFF4A8AFF);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final generated = ColorScheme.fromSeed(
      seedColor: brandNavy,
      brightness: brightness,
    );
    final scheme = generated.copyWith(
      primary: isDark ? brandPrimaryDark : brandNavy,
      onPrimary: Colors.white,
      surface: isDark ? const Color(0xFF121417) : const Color(0xFFFAFBFD),
      surfaceContainerLowest: isDark
          ? const Color(0xFF0C0E10)
          : const Color(0xFFFFFFFF),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Metrics.cardRadius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Metrics.controlRadius),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

abstract final class Metrics {
  static const double pagePadding = 16;
  static const double cardPadding = 16;
  static const double sectionGap = 18;
  static const double cardRadius = 12;
  static const double controlRadius = 10;
}
