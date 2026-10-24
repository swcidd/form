# Attribution and licences

FORM ships two font families, an exercise catalogue, and artwork that other
people made. Some of those licences require a notice wherever the work is
redistributed, and an APK is a redistribution, so this file is the notice. It
is also the citation list for the written report: every external source the app
uses, with its licence, in one place.

## Fonts

The type scale uses two families, bundled as assets so the app never fetches a
font at runtime (see `pubspec.yaml` and `test/fonts_test.dart`).

| Family | Weights bundled | Licence | Copyright |
| --- | --- | --- | --- |
| **Inter** | 400, 500, 600, 700 | SIL Open Font License 1.1 | 2020 The Inter Project Authors |
| **Barlow Condensed** | 600, 700 | SIL Open Font License 1.1 | 2017 Jeremy Tribby |

Full licence texts, as required by the OFL:

- [`docs/licenses/OFL-Inter.txt`](licenses/OFL-Inter.txt)
- [`docs/licenses/OFL-BarlowCondensed.txt`](licenses/OFL-BarlowCondensed.txt)

Neither family is modified: the files are the ones Google Fonts serves, taken
from the URL recorded in the `google_fonts` package's own font metadata.

## Exercise data

The library screen shows exercises from two places: the live wger API, and one
canonical catalogue bundled in the app for when the API is unreachable. The
canonical file is generated from the two open data sets below.

| Source | How the app gets it | Licence | Notes |
| --- | --- | --- | --- |
| **[wger.de](https://wger.de)** | `GET https://wger.de/api/v2/exerciseinfo/` — public, no API key | CC BY-SA 3.0 or 4.0 **per entry**, author per entry | Every exercise the API returns carries its own `license` and `license_author` fields. |
| **[exercemus/exercises](https://github.com/exercemus/exercises)** | `tool/exercise_sources/exercemus.json`, source for the bundled catalogue | MIT, © 2022 exercemus | See [`docs/licenses/exercemus-MIT.txt`](licenses/exercemus-MIT.txt). The data set is itself curated from wger.de and wrkout/exercises.json. |
| **[free-exercise-db](https://github.com/yuhonas/free-exercise-db)** | `tool/exercise_sources/free-exercise-db.json`, source for the bundled catalogue | The Unlicense (public domain) | No conditions; recorded here for completeness. |

`tool/build_exercises.dart` merges the two offline sources into
`assets/data/exercises.json` and normalises their muscle and equipment
vocabularies. Instruction text is carried through, not rewritten.

How this shows up in the app: the library screen carries a permanent
attribution line under the grid naming all three sources and their licences, and
the offline banner names the API that could not be reached. The build script
merges the two offline sets and normalises muscle and equipment vocabulary;
instruction text is carried through, not rewritten.

Known gap: wger returns an author per entry and the app does not display it.
The source and the licence are named, the individual contributor is not yet.
Closing that means carrying `license_author` through `LibraryExercise` and
printing it on the card.

## Icons

| Asset | Source | Licence |
| --- | --- | --- |
| `assets/icons/activity.svg`, `chart-no-axes-combined.svg`, `dumbbell.svg`, `library.svg`, `user-round.svg` | [Lucide](https://lucide.dev) | ISC |
| `assets/images/dumbbell-large-minimalistic-svgrepo-com.svg` | [SVG Repo](https://www.svgrepo.com/svg/524514/dumbbell-large-minimalistic) | CC0 (no attribution required) |

## Photography

| Asset | Source | Licence |
| --- | --- | --- |
| `assets/images/program_hero.png` | **to be recorded** | **to be recorded** |
| `assets/images/workout_hero.png` | **to be recorded** | **to be recorded** |
| `assets/images/profile_avatar.png` | **to be recorded** | **to be recorded** |

These three were already in `assets/images/` and carry no metadata saying where
they came from. They need a source and a licence recorded before submission —
either an entry here, or replaced with artwork whose provenance is known.

## Not in the APK

- No API keys or credentials: the wger endpoints used are public and unauthenticated.
- No seeded account data: exercise data is the only content the app ships.
- Nothing about a user's own sessions leaves the device — they live in the local
  SQLite database (`plus_one.db`).

## Package licences

Third-party Dart and Flutter packages are listed with their versions in
`pubspec.yaml` and resolved in `pubspec.lock`. Their licences are the ones
published on pub.dev for those versions; the report's tooling section cites
each one it names.
