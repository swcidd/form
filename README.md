<div align="center">

# FORM

**A fitness tracker that maps every rep, every set, every session.**

*Log the workout. See the progress. Beat yourself — by one.*

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-FFA000?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-FFA000?style=for-the-badge)](#download)

</div>

---

## Why FORM?

Tracking your lifts shouldn't feel like homework. Most apps either bury your numbers under five layers of menus or lock them behind a subscription. FORM does one thing and does it well: **it remembers what you lifted so you can see yourself getting stronger.**

- ✍️ **Log in seconds** — exercises, sets, reps, and weight in a few taps.
- 📈 **Watch the line go up** — every lift charted against your previous sessions.
- 🏆 **Catch your PRs** — personal records surface automatically, no digging.
- 📅 **Never lose your streak** — a calendar of everything you've done.
- 🎯 **Know what's next** — each session suggests a target based on your own history.

No account required. No ads. Your workout data stays on your device.

---

## Screens

| Screen | What you get |
| --- | --- |
| **Home** | Today's plan, a quick-start button, and a snapshot of recent activity and streaks. |
| **Workout Details** | The full log for a session — exercises, sets, reps, weight — with progress charts and PRs per lift. |
| **Calendar** | Browse past sessions and schedule upcoming ones; tap a day to see what you did. |
| **Profile** | Your stats, goals, and settings — total workouts, longest streak, achievements. |

<!-- TODO: add screenshots here once the UI is final
| Home | Details |
| --- | --- |
| ![Home](docs/screenshots/home.png) | ![Details](docs/screenshots/details.png) |
-->

---

## Features

- **Workout logging** — record exercises, sets, reps, and weight as you go
- **Exercise library** — pick from common lifts or add your own
- **Progress charts** — strength trends over weeks and months
- **Personal records** — automatic PR detection and display
- **Workout calendar** — history and scheduling in one view
- **Streaks & stats** — consistency at a glance
- **Goals & body metrics** — body weight, targets, and units
- **Flexible data** — works offline, syncs with a public exercise REST API
- **Empty, loading & error states** — the app tells you what's happening, always

---

## Tech stack

| Layer | Choice |
| --- | --- |
| Framework | Flutter |
| Language | Dart |
| State management | `provider` (`ChangeNotifier`) |
| Networking | `http` + JSON model classes |
| Charts | `fl_chart` |
| Storage | `shared_preferences` / `sqflite` |

Architecture follows a clean separation: `models/` holds plain data classes, `services/` talks to the API, `providers/` owns app state, `screens/` renders pages, and `widgets/` holds reusable UI.

---

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x
- An Android emulator, iOS simulator, or Chrome for web

### Run it

```bash
git clone https://github.com/swcidd/form.git
cd form
flutter pub get
flutter run
```

### Build a release APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Project structure

```
lib/
├── main.dart          # app entry, theme, routes, providers
├── models/            # Workout, Exercise, Set, Profile
├── services/          # API client, local storage
├── providers/         # ChangeNotifiers for shared state
├── screens/           # Home, WorkoutDetails, Calendar, Profile
└── widgets/           # reusable cards, charts, inputs
```

---

## Roadmap

- [x] Project scaffold and setup
- [ ] Workout logging with CRUD
- [ ] Provider-based shared state
- [ ] REST API integration
- [ ] Progress charts and PR detection
- [ ] Custom icon, splash screen, release build
- [ ] Documentation paper

---

## Contributing

Issues and pull requests are welcome. Please use feature branches (`feature/<name>`) and open a PR against `master` rather than pushing directly.

```bash
git checkout -b feature/my-feature
# ...make changes...
git commit -m "Add clear description of what changed"
git push origin feature/my-feature
```

---

## Team

| Member | Role |
| --- | --- |
| **Sherwin Sid S. Sañol** ([@swcidd](https://github.com/swcidd)) | UI, state management, API/data layer, Git, documentation |

Built for **SE2142 — Software Engineering Tools and Practices**.

---

## Data sources and licences

FORM does not invent its exercise catalogue — it reads it from three places.
The licences that ask for attribution get one on screen and in
**[docs/ATTRIBUTION.md](docs/ATTRIBUTION.md)**, which also carries the notice
texts and the two font licences.

| Source | Licence |
| --- | --- |
| [wger.de](https://wger.de) REST API — the live catalogue | CC BY-SA 3.0/4.0, per entry |
| [exercemus/exercises](https://github.com/exercemus/exercises) — bundled offline fallback | MIT, © 2022 exercemus |
| [free-exercise-db](https://github.com/yuhonas/free-exercise-db) — bundled offline fallback | The Unlicense (public domain) |

The interface icons are [Lucide](https://lucide.dev) (ISC). Inter and Barlow
Condensed are bundled with the app under the SIL Open Font License 1.1, so no
font is fetched at runtime.

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
