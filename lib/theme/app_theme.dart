import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Timing and easing shared by every transition in the app.
abstract final class AppMotion {
  /// Fast response for presses and toggles.
  static const Duration press = Duration(milliseconds: 160);

  /// Default for state changes inside a screen.
  static const Duration ui = Duration(milliseconds: 200);

  /// Route transitions and sheet entrances.
  static const Duration route = Duration(milliseconds: 250);

  /// Starts fast, settles gently. Entering elements.
  static const Cubic easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Symmetric acceleration. Moving elements.
  static const Cubic easeInOut = Cubic(0.77, 0, 0.175, 1);
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ColorScheme colorScheme(Brightness brightness) {
    return brightness == Brightness.light ? _lightScheme : _darkScheme;
  }

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = colorScheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: AppTypography.textTheme(scheme),
      scaffoldBackgroundColor: isLight
          ? AppColors.canvas
          : AppColors.canvasDark,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.canvas : AppColors.canvasDark,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme(scheme).headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.onSurfaceVariant,
          elevation: 0,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: AppTypography.textTheme(scheme).labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: AppTypography.textTheme(
            scheme,
          ).labelLarge?.copyWith(color: scheme.onSurface),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(44, 44),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: AppTypography.textTheme(
            scheme,
          ).labelLarge?.copyWith(color: scheme.onSurface),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: isLight ? AppColors.sage100 : AppColors.inkSubtle,
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.textTheme(scheme).labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        labelStyle: AppTypography.textTheme(scheme).labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 4,
          vertical: AppSpacing.xs,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppTypography.textTheme(
          scheme,
        ).bodyMedium?.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.md),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Plus One light: cream canvas, ink text, sage secondary.
  /// Surface containers are white; hairlines are sage100.
  /// Primary actions are ink; lime is the signature accent.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.cream,
    primaryContainer: AppColors.warmCream,
    onPrimaryContainer: AppColors.ink,
    secondary: AppColors.sage600,
    onSecondary: AppColors.cream,
    secondaryContainer: AppColors.sage50,
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.lime,
    onTertiary: AppColors.ink,
    tertiaryContainer: AppColors.lime,
    onTertiaryContainer: AppColors.ink,
    error: AppColors.rust,
    onError: AppColors.cream,
    errorContainer: AppColors.peach,
    onErrorContainer: AppColors.rust,
    surface: AppColors.white,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.sage600,
    outline: AppColors.sage300,
    outlineVariant: AppColors.sage100,
    shadow: Color(0x00000000),
    scrim: Color(0x00000000),
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.cream,
    inversePrimary: AppColors.lime,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.warmCream,
    surfaceContainer: AppColors.cream,
    surfaceContainerHigh: AppColors.sage0,
    surfaceContainerHighest: AppColors.sage50,
  );

  /// Plus One dark: ink canvas, cream text. Placeholder until dark frames exist.
  /// Mirrors light semantic roles with inverted values.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.lime,
    onPrimary: AppColors.ink,
    primaryContainer: AppColors.inkMuted,
    onPrimaryContainer: AppColors.lime,
    secondary: AppColors.sage300,
    onSecondary: AppColors.ink,
    secondaryContainer: AppColors.inkSubtle,
    onSecondaryContainer: AppColors.cream,
    tertiary: AppColors.lime,
    onTertiary: AppColors.ink,
    tertiaryContainer: AppColors.inkSubtle,
    onTertiaryContainer: AppColors.lime,
    error: AppColors.rust,
    onError: AppColors.cream,
    errorContainer: Color(0xFF3D1A12),
    onErrorContainer: AppColors.peach,
    surface: AppColors.inkMuted,
    onSurface: AppColors.cream,
    onSurfaceVariant: AppColors.sage300,
    outline: AppColors.sage500,
    outlineVariant: AppColors.inkSubtle,
    shadow: Color(0x00000000),
    scrim: Color(0x00000000),
    inverseSurface: AppColors.cream,
    onInverseSurface: AppColors.ink,
    inversePrimary: AppColors.ink,
    surfaceContainerLowest: AppColors.ink,
    surfaceContainerLow: AppColors.inkMuted,
    surfaceContainer: AppColors.inkSubtle,
    surfaceContainerHigh: AppColors.inkSubtle,
    surfaceContainerHighest: AppColors.sage100,
  );
}
