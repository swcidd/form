import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_page_transitions.dart';
import 'app_typography.dart';

/// Timing and easing shared by every transition in the app.
///
/// Four movements — a press, a change inside a screen, a page and a sheet —
/// cover everything the app animates. The tokens are named for what they move
/// rather than for how long they take, so a screen asks for "a press" instead
/// of inventing another number between 90 and 300.
abstract final class AppMotion {
  /// Pointer down. Short enough that the surface answers the thumb.
  static const Duration pressDown = Duration(milliseconds: 90);

  /// Pointer up. Slower than the press, so the release has weight.
  static const Duration pressUp = Duration(milliseconds: 160);

  /// Default for state changes inside a screen.
  static const Duration ui = Duration(milliseconds: 200);

  /// Page arrival. Longer than the exit, so leaving feels decided.
  static const Duration routeIn = Duration(milliseconds: 260);

  /// Page departure.
  static const Duration routeOut = Duration(milliseconds: 200);

  /// Sheet arrival.
  static const Duration sheetIn = Duration(milliseconds: 300);

  /// Sheet departure.
  static const Duration sheetOut = Duration(milliseconds: 220);

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
      // Android defaults to a zoom that belongs to the platform's own chrome.
      // FORM arrives with a fade and a short rise instead, and keeps Apple's
      // builder where the back-swipe is part of the contract.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
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
          textStyle: AppTypography.textTheme(scheme).labelLarge
              ?.copyWith(color: scheme.onSurface),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(44, 44),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: AppTypography.textTheme(scheme).labelLarge
              ?.copyWith(color: scheme.onSurface),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: Colors.transparent,
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.textTheme(scheme).labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
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
        contentTextStyle: AppTypography.textTheme(scheme).bodyMedium
            ?.copyWith(color: scheme.onInverseSurface),
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

  /// FORM light: cream canvas, ink text, sage secondary.
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

  /// FORM dark: ink canvas, cream text, lime accents.
  /// Mirrors the semantic roles in the Figma Theme collection.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.lime,
    onPrimary: AppColors.ink,
    primaryContainer: AppColors.inkMuted,
    onPrimaryContainer: AppColors.lime,
    secondary: AppColors.sage300,
    onSecondary: AppColors.ink,
    secondaryContainer: AppColors.inkSubtle,
    onSecondaryContainer: AppColors.warmCream,
    tertiary: AppColors.lime,
    onTertiary: AppColors.ink,
    tertiaryContainer: AppColors.inkSubtle,
    onTertiaryContainer: AppColors.lime,
    error: AppColors.rust,
    onError: AppColors.warmCream,
    errorContainer: Color(0xFF3D1A12),
    onErrorContainer: AppColors.peach,
    surface: AppColors.inkMuted,
    onSurface: AppColors.warmCream,
    onSurfaceVariant: AppColors.sage300,
    outline: AppColors.inkSubtle,
    outlineVariant: AppColors.inkSubtle,
    shadow: Color(0x00000000),
    scrim: Color(0x00000000),
    inverseSurface: AppColors.warmCream,
    onInverseSurface: AppColors.ink,
    inversePrimary: AppColors.ink,
    surfaceContainerLowest: AppColors.ink,
    surfaceContainerLow: AppColors.inkMuted,
    surfaceContainer: AppColors.inkSubtle,
    surfaceContainerHigh: AppColors.inkSubtle,
    surfaceContainerHighest: Color(0xFF2B312A),
  );
}
