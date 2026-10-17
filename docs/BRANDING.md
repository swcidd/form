# Brand assets

The launcher icon and the splash mark are generated, not hand-drawn, so they can
be changed deliberately and the change reviewed:

```bash
python3 tool/generate_brand_assets.py   # writes assets/branding/*.png
dart run flutter_launcher_icons         # → Android mipmaps + adaptive icon, iOS AppIcon
dart run flutter_native_splash:create   # → Android splash, 12+ included
```

All three outputs are committed, so a build never depends on the script or on
Python having been installed.

## The mark

**"+1" set in Barlow Condensed Bold**, lime on ink: the app's signature colour on
its ink ground, in the face its own display sizes already use (`assets/fonts/`,
declared in `pubspec.yaml`). That makes the icon typographic rather than
illustrative, and it means nothing in it needs a licence — there is no
third-party artwork in the launcher icon or the splash (see
[ATTRIBUTION.md](ATTRIBUTION.md) for what *is* third-party).

It also says what the app is for: beat yourself by one.

## What each file is for

| File | Size | Used as |
| --- | --- | --- |
| `assets/branding/app_icon.png` | 1024×1024, opaque ink | The icon source for iOS and the legacy Android icon |
| `assets/branding/app_icon_foreground.png` | 1024×1024, transparent | The Android 8+ adaptive icon foreground, drawn smaller because the launcher masks it to a shape of its own choosing |
| `assets/branding/splash_logo.png` | 1024×1024, transparent | The mark on the splash, set in ink to sit on cream |

The script renders the text, crops to its own ink and re-centres it, so the
proportions are computed from the font's metrics rather than guessed — a
different face would still land centred without editing magic numbers.

## Choices worth stating

- **The splash is cream, not ink.** The app is light-only, so starting dark
  would be a flash of a colour the user then never sees again. Android 12 draws
  its own splash from `windowSplashScreenBackground`, which is set to the same
  cream.
- **The splash covers Android only.** Generating it for iOS rewrites
  `Info.plist`, the launch storyboard and the Xcode project wholesale — a large,
  unreviewable diff for a platform this submission does not build. iOS keeps its
  default launch storyboard and still gets the new app icon. The web target is
  not part of the app either.
- **The icon ships on both mobile platforms** because
  `flutter_launcher_icons` regenerates them from one source; leaving iOS on the
  Flutter template icon would be an inconsistency with no upside.
