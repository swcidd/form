# Two DevTools cases

DevTools is most useful when it answers a question you cannot answer by reading
code. These are the two questions FORM's build raised, what the tool said, and
what the code did about it.

Both start from a profile or release build, because a debug build measures the
debugger:

```bash
flutter build apk --release --analyze-size --target-platform android-arm64
dart devtools --appSizeBase=~/.flutter-devtools/apk-code-size-analysis_01.json
```

---

## Case 1 — my SVG renderer cost more than my app

**The question.** The release APK is 20 MB. How much of that is mine, and where
is the rest going?

**What the App Size tool showed** (arm64 release build, Flutter 3.47.5):

| Part | Size | Share |
| --- | ---: | ---: |
| `lib/arm64-v8a/libflutter.so` — the engine | 11.75 MB | 58% |
| `lib/arm64-v8a/libapp.so` — Dart AOT | 6.75 MB | 33% |
| `assets/flutter_assets` — fonts, photos, catalogue | 1.24 MB | 6% |
| `classes.dex`, `res/`, manifest | 0.31 MB | 2% |
| **APK on disk** | **20 MB** | |

Inside the 1.24 MB of assets:

| Asset group | Size | What it is |
| --- | ---: | --- |
| `fonts/` | 673 KB | Four Inter weights (607 KB) + two Barlow Condensed (60 KB) |
| `images/` | 400 KB | Three photographs: workout hero 145 KB, profile avatar 129 KB, program hero 125 KB |
| `data/` | 67 KB | The one canonical exercise catalogue, generated from two sources |
| `MaterialIcons-Regular.otf` | **4.8 KB** | Tree-shaken by the build, from ~1.6 MB |

Inside `libapp.so`, attributed by package:

| Package | Size |
| --- | ---: |
| `package:flutter` | 2.85 MB |
| framework / AOT runtime | 2.42 MB |
| **`package:plus_one` — this entire app** | **281 KB** |
| `package:vector_graphics_compiler` + `xml` + `petitparser` + `vector_math` + `vector_graphics` + `vector_graphics_codec` + `path_parsing` | **≈ 380 KB** |
| `package:material_color_utilities` | 67 KB |
| `package:intl` | 66 KB |
| `package:sqflite_common` | 28 KB |
| `package:google_fonts` | 20 KB |
| `package:equatable` | 18 KB |
| `package:provider` | 14 KB |

**The finding.** `flutter_svg` — one dependency, used to draw **five icons** that
are 1.1 KB on disk — compiles to roughly 380 KB of Dart AOT. That is more code
than every screen, provider, repository and test helper in the app put together
(281 KB). The renderer outweighs the thing it renders.

**What I did about it.** Nothing, and here is the argument for nothing: 380 KB is
1.9% of a 20 MB APK, the icons are part of the design language (Lucide, drawn at
whatever size the layout needs rather than shipped at three resolutions each),
and replacing them with a font would mean regenerating the icon set from a
different source — a design change disguised as a size optimisation. It is
recorded here as a known cost rather than pretended to be free.

**What I would change first, if the APK had to shrink.** In order:

1. `flutter_svg` (≈ 380 KB of AOT) → four icons from an icon font, one from the
   existing PNG pipeline. Biggest single win, smallest visual risk.
2. Inter (607 KB): the design uses four weights, but the *text* only needs 400,
   600 and 700; dropping the medium weight saves 154 KB, and subsetting the
   remaining three to Latin + the punctuation the app actually prints saves
   more. Both are build-time steps, not design changes.
3. The three photographs (400 KB): re-encoding as WebP at the same dimensions
   should halve them. The current PNGs are what the design exported.

**What the tool confirmed as *not* a problem:** Material icons tree-shake from
~1.6 MB to 4.8 KB, so the icon font is not the cost people assume it is, and the
app's own Dart code is not where the megabytes live. Guessing would have got
both of those wrong.

---

## Case 2 — a frame that lasted a tenth of a second

**The symptom.** Signing in with a real account made the spinner stop for a beat
before the app window appeared. 120-250 ms of nothing, every time, on a fast
machine — so several frames dropped on a phone.

**How to see it.** In a profile build, open DevTools → **Performance**, press
record, sign in, stop. The **UI** track shows a single frame far taller than the
rest — the fingerprint of synchronous work on the main isolate. Opening the CPU
profiler for that frame shows the call tree going

```
AuthRepository.signIn
└── LocalAuthRepository._verify
    └── PasswordHasher.verify
        └── Hmac(sha256) × iterations      ← the frame dies here
```

The hashing is deliberate — it is what makes a stolen `plus_one.db` expensive to
read (see [AUTH.md](AUTH.md)) — but it was running on the isolate that draws the
screen.

**The measurement.** A benchmark of the same code path, on the development
machine (AMD Ryzen 5 5600H, Dart JIT), five runs each:

| Iterations | Median | Runs |
| ---: | ---: | --- |
| 12 000 | **105 ms** | 103, 104, 105, 105, 133 |
| 40 000 | **254 ms** | 204, 227, 254, 287, 321 |

A frame is 16.7 ms at 60 Hz. Twelve thousand iterations is one long frame; forty
thousand is fifteen of them. 12 000 was chosen as the default because it is the
largest cost that still reads as "a moment" rather than "a hang", and the count
is stored inside the verifier string so it can be raised later without
invalidating anybody's password.

**The fix.** The hashing now runs on a worker isolate via `compute`, and the UI
thread only awaits it:

```dart
Future<String> _hash(String password) => compute(_hashOffIsolate, (
      password: password,
      salt: salt,
    ));
```

In the same Performance recording, the long task moves off the UI track to a
worker isolate: the UI keeps drawing the spinner at frame rate while the isolate
computes, and the total wall-clock time barely changes. That is the correct
trade — the work still happens, it just no longer happens on the thread that owes
the user 60 frames a second.

**The rule it produced.** The UI never hashes, and it never sees a hash: the
repository takes a password and returns a session. That is also why the hasher's
iteration count can change later without touching a screen.

---

## What this changed in the code

- `PasswordHasher` has a measured default (12 000) and stores its cost per
  account, so raising it is a per-account upgrade rather than a migration.
- Hashing and verifying go through `compute`; nothing on the frame path does
  100 ms of work.
- The size analysis is a build-time artefact, not a habit: `--analyze-size` is
  the command in [BUILD.md](BUILD.md) and the JSON is regenerated whenever the
  assets or dependencies change.
