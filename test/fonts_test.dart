import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plus_one/theme/app_typography.dart';

/// The app ships its two families as assets, so `google_fonts` never has to
/// fetch one at runtime. That only holds while the asset names match what it
/// looks for: it resolves a bundled font by finding an asset path that ends in
/// `"<family>-<variant>.ttf"`, using its own family id - which for Barlow
/// Condensed has no space in it. Rename a file and nothing fails, the app just
/// quietly goes back to the network - unless something is watching, which is
/// what these tests are for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // main() does this before the first frame; a test builds styles without
  // running main, so it has to say so itself. Otherwise a style here would try
  // to download from fonts.gstatic.com, and the test binding answers every
  // request with a 400.
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late Set<String> assets;

  setUpAll(() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    assets = manifest.listAssets().toSet();
  });

  /// The names `google_fonts` derives from a family and a variant, in the form
  /// its asset lookup expects to find them on disk.
  const bundled = <String>[
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/BarlowCondensed-SemiBold.ttf',
    'assets/fonts/BarlowCondensed-Bold.ttf',
  ];

  /// The display face is Barlow Condensed, the UI face is Inter. google_fonts
  /// drops the space from the family id, which is why it reads like that here.
  const barlow = 'BarlowCondensed';
  const inter = 'Inter';

  test('every family and weight the scale asks for is in the bundle', () {
    for (final path in bundled) {
      expect(assets, contains(path), reason: '$path is not bundled');
    }
  });

  test('the display face is Barlow Condensed and the UI face is Inter', () {
    final text = AppText.of(ThemeData.light().colorScheme);

    expect(text.dataHero.fontFamilyFallback, contains(barlow));
    expect(text.exerciseName.fontFamilyFallback, contains(barlow));
    expect(text.labelCaps.fontFamilyFallback, contains(inter));
    expect(text.setValue.fontFamilyFallback, contains(inter));
  });

  test('every family the styles name is one the app actually ships', () {
    final text = AppText.of(ThemeData.light().colorScheme);

    final families = <String>{
      for (final style in [
        text.dataHero,
        text.dataLarge,
        text.dataChange,
        text.labelCaps,
        text.annotation,
        text.metric,
        text.dataMetric,
        text.setValue,
        text.setDim,
        text.exerciseName,
        text.exerciseMeta,
        text.previousPerf,
        text.programBadge,
        text.programName,
        text.programMeta,
        text.readyScore,
      ])
        style.fontFamilyFallback?.single ?? '<none>',
    };

    expect(families, unorderedEquals({inter, barlow}));
    for (final family in families) {
      expect(
        bundled.any((path) => path.contains('/$family-')),
        isTrue,
        reason:
            '$family is named by a style but no file for it is bundled, so the '
            'text would render in the platform substitute',
      );
    }
  });
}
