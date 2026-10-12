import 'package:flutter/material.dart';

/// Plus One (FORM) palette — extracted from the Figma design system.
///
/// Ground: cream / warm cream / white
/// Ink: near-black greens (not pure black)
/// Sage ramp: light → mid, for chips, rules, secondary text
/// Accents: lime #D5FC61 (signature), rust #C94C32, peach #F8EAE3
///
/// https://www.figma.com/design/3aDilw2SiRynw2gWFn0ZNk/Plus-One-Design
abstract final class AppColors {
  // --- Palette --------------------------------------------------------------

  // Ground
  static const Color cream = Color(0xFFFAFAF7);
  static const Color warmCream = Color(0xFFF2F1E9);
  static const Color white = Color(0xFFFFFFFF);

  // Ink (near-black greens)
  static const Color ink = Color(0xFF121512);
  static const Color inkSoft = Color(0xFF202723);
  static const Color inkMuted = Color(0xFF20251F);
  static const Color inkSubtle = Color(0xFF353C31);

  // Sage ramp (light → mid)
  static const Color sage0 = Color(0xFFE7E9E3);
  static const Color sage50 = Color(0xFFE6EAD8);
  static const Color sage100 = Color(0xFFD8DCD0);
  static const Color sage300 = Color(0xFF9DA697);
  static const Color sage500 = Color(0xFF727972);
  static const Color sage600 = Color(0xFF677060);

  // Accents
  static const Color lime = Color(0xFFD5FC61); // signature
  static const Color rust = Color(0xFFC94C32);
  static const Color peach = Color(0xFFF8EAE3);

  // --- Semantic aliases -----------------------------------------------------

  /// Page background (light mode only for now).
  static const Color canvas = cream;

  /// Primary text on canvas.
  static const Color onCanvas = ink;

  /// Secondary text on canvas.
  static const Color onCanvasSecondary = sage600;

  /// Tertiary / label text on canvas — use at ≥11px only (fails AA at 10px).
  static const Color onCanvasTertiary = sage300;

  /// Card / elevated surface.
  static const Color surface = white;

  /// Hairline divider on light.
  static const Color hairline = sage100;

  /// Primary action / link.
  static const Color action = ink;

  /// Accent interactive (lime on dark, rust on light for CTAs).
  static const Color accent = lime;

  /// Destructive / error.
  static const Color destructive = rust;
  static const Color destructiveBg = peach;

  // --- Dark mode (placeholder — not designed in Figma yet) ------------------
  // These mirror light for now; replace when dark frames are available.
  static const Color canvasDark = ink;
  static const Color onCanvasDark = cream;
  static const Color onCanvasSecondaryDark = sage300;
  static const Color onCanvasTertiaryDark = sage500;
  static const Color surfaceDark = inkMuted;
  static const Color hairlineDark = inkSubtle;
  static const Color actionDark = lime;
  static const Color accentDark = lime;
  static const Color destructiveDark = rust;
  static const Color destructiveBgDark = Color(0xFF3D1A12);
}

/// Corner radius scale — square per Figma (no rounded corners emitted).
abstract final class AppRadius {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius control = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
  static const BorderRadius sharp = BorderRadius.zero;
  static const BorderRadius tag = BorderRadius.all(Radius.circular(xs));
}

/// 4pt spacing grid — 24px gutter matches Figma.
abstract final class AppSpacing {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double gutter = 24;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets page = EdgeInsets.all(gutter);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(
    horizontal: gutter,
  );
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardTight = EdgeInsets.all(sm);
}

/// Hairline and icon stroke weights.
abstract final class AppStroke {
  static const double hairline = 1;
  static const double icon = 1.8;
}
