import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale from the Figma design system.
///
/// Two families, no third:
/// - Display: Barlow Condensed SemiBold/Bold 23–40px, lh 1.0em, uppercase
/// - UI: Inter Regular→Bold 8–14px, comfortable at 12–14px
///
/// 31 styles total, but really ~6 sizes with weight variants.
abstract final class AppTypography {
  static TextStyle _inter({
    required double fontSize,
    required double height,
    required double letterSpacing,
    required FontWeight fontWeight,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle _barlow({
    required double fontSize,
    required double height,
    required double letterSpacing,
    required FontWeight fontWeight,
    Color? color,
  }) {
    return GoogleFonts.barlowCondensed(
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Builds the full text theme for a color scheme.
  ///
  /// The M3 slots are filled from the Figma scale so component text
  /// (app bar, navigation labels, buttons) inherits the same rhythm as the
  /// hand-written screen text instead of falling back to Roboto defaults.
  static TextTheme textTheme(ColorScheme scheme) {
    return TextTheme(
      // Display: Barlow Condensed Bold 40/40, -1.6, w700
      displayLarge: _barlow(
        fontSize: 40,
        height: 1.0,
        letterSpacing: -1.6,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      // Display: Barlow Condensed SemiBold 32/32, -1.28, w600
      headlineLarge: _barlow(
        fontSize: 32,
        height: 1.0,
        letterSpacing: -1.28,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      // Display: Barlow Condensed SemiBold 28/28, -1.12, w600
      headlineMedium: _barlow(
        fontSize: 28,
        height: 1.0,
        letterSpacing: -1.12,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      // Display: Barlow Condensed SemiBold 24/24, -0.96, w600
      headlineSmall: _barlow(
        fontSize: 24,
        height: 1.0,
        letterSpacing: -0.96,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      // Title: Barlow Condensed SemiBold 20/20, -0.8, w600
      titleLarge: _barlow(
        fontSize: 20,
        height: 1.0,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      // Body: Inter Regular 16/24, 0, w400
      titleMedium: _inter(
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      // Body: Inter Regular 14/20, 0, w400
      titleSmall: _inter(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      bodyLarge: _inter(
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      bodyMedium: _inter(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      bodySmall: _inter(
        fontSize: 12,
        height: 18 / 12,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      // Button labels: Inter SemiBold 14/20, 0, w600
      labelLarge: _inter(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0,
        fontWeight: FontWeight.w600,
        color: scheme.onPrimary,
      ),
      // Label caps: Inter SemiBold 11/14, 0.88, w600, uppercase
      labelMedium: _inter(
        fontSize: 11,
        height: 14 / 11,
        letterSpacing: 0.88,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
      // Annotation: Inter Regular 10/14, 0, w400
      labelSmall: _inter(
        fontSize: 10,
        height: 14 / 10,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Roles that do not map onto a Material text theme slot.
///
/// Kept off [TextTheme] because Material reserves those slots for its own
/// components; reusing them here would silently restyle every app bar and
/// dialog in the app.
class AppText {
  const AppText._(this._scheme);

  final ColorScheme _scheme;

  static AppText of(ColorScheme scheme) => AppText._(scheme);

  /// Display metric: Barlow Condensed Bold 64/64, -2.56, w700. Hero numbers.
  TextStyle get dataHero => AppTypography._barlow(
    fontSize: 64,
    height: 1.0,
    letterSpacing: -2.56,
    fontWeight: FontWeight.w700,
    color: _scheme.onSurface,
  );

  /// Display metric: Barlow Condensed SemiBold 66/66, -2.64, w600. Large numbers.
  TextStyle get dataLarge => AppTypography._barlow(
    fontSize: 66,
    height: 1.0,
    letterSpacing: -2.64,
    fontWeight: FontWeight.w600,
    color: _scheme.onSurface,
  );

  /// Display metric: Barlow Condensed SemiBold 30/30, -1.2, w600. Change %.
  TextStyle get dataChange => AppTypography._barlow(
    fontSize: 30,
    height: 1.0,
    letterSpacing: -1.2,
    fontWeight: FontWeight.w600,
    color: _scheme.onSurface,
  );

  /// Label caps: Inter SemiBold 11/14, 0.88, w600, uppercase. Section eyebrows.
  TextStyle get labelCaps => AppTypography._inter(
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0.88,
    fontWeight: FontWeight.w600,
    color: _scheme.onSurfaceVariant,
  );

  /// Annotation: Inter Regular 10/14, 0, w400. Timestamps and identifiers.
  TextStyle get annotation => AppTypography._inter(
    fontSize: 10,
    height: 14 / 10,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: _scheme.onSurfaceVariant,
  );

  /// Compact value used inside rows where [dataHero] would dominate.
  TextStyle get metric => AppTypography._barlow(
    fontSize: 32,
    height: 1.0,
    letterSpacing: -1.28,
    fontWeight: FontWeight.w600,
    color: _scheme.onSurface,
  );

  /// Metric tile value: Barlow Condensed SemiBold 36/40, -1.08, w700. Big single numbers on stat tiles.
  TextStyle get dataMetric => AppTypography._barlow(
    fontSize: 36,
    height: 40 / 36,
    letterSpacing: -1.08,
    fontWeight: FontWeight.w700,
    color: _scheme.onSurface,
  );

  /// Set table value: Inter SemiBold 14/20, 0, w600. Tabular figures.
  TextStyle get setValue => AppTypography._inter(
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
    color: _scheme.onSurface,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Set table dim: Inter Regular 10/14, 0, w400. Tabular figures.
  TextStyle get setDim => AppTypography._inter(
    fontSize: 10,
    height: 14 / 10,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: _scheme.onSurfaceVariant,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Exercise name: Barlow Condensed Bold 40/40, -1.6, w700.
  TextStyle get exerciseName => AppTypography._barlow(
    fontSize: 40,
    height: 1.0,
    letterSpacing: -1.6,
    fontWeight: FontWeight.w700,
    color: _scheme.onSurface,
  );

  /// Exercise meta: Inter Regular 12/18, 0, w400.
  TextStyle get exerciseMeta => AppTypography._inter(
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: _scheme.onSurfaceVariant,
  );

  /// Previous performance: Inter Regular 11/14, 0, w400.
  TextStyle get previousPerf => AppTypography._inter(
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: _scheme.onSurfaceVariant,
  );

  /// Program badge: Barlow Condensed SemiBold 25/25, -1.0, w600.
  TextStyle get programBadge => AppTypography._barlow(
    fontSize: 25,
    height: 1.0,
    letterSpacing: -1.0,
    fontWeight: FontWeight.w600,
    color: _scheme.onSurface,
  );

  /// Program name: Barlow Condensed Bold 36/36, -1.44, w700.
  TextStyle get programName => AppTypography._barlow(
    fontSize: 36,
    height: 1.0,
    letterSpacing: -1.44,
    fontWeight: FontWeight.w700,
    color: _scheme.onSurface,
  );

  /// Program meta: Inter Regular 12/18, 0, w400.
  TextStyle get programMeta => AppTypography._inter(
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: _scheme.onSurface,
  );

  /// Ready score: Barlow Condensed SemiBold 28/28, -1.12, w600.
  TextStyle get readyScore => AppTypography._barlow(
    fontSize: 28,
    height: 1.0,
    letterSpacing: -1.12,
    fontWeight: FontWeight.w600,
    color: _scheme.onSurface,
  );
}

extension AppTextStyle on BuildContext {
  /// `context.text.dataHero`
  AppText get text => AppText.of(Theme.of(this).colorScheme);
}
