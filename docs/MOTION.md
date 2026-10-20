# Motion

FORM animates four things and no more: a page arriving, a sheet arriving, a
surface answering a press, and state changes inside a screen. Everything else
changes instantly, including the gate that swaps the signed-in and signed-out
windows and the progress bar that fills as a session is logged.

The rules live in `lib/theme/app_theme.dart` (`AppMotion`), the page transition
in `lib/theme/app_page_transitions.dart`, and the press in
`lib/widgets/pressable.dart`.

## Tokens

| Token | Value | Used by |
| --- | --- | --- |
| `pressDown` | 90 ms | `Pressable` while a finger is down |
| `pressUp` | 160 ms | `Pressable` on release |
| `ui` | 200 ms | state changes inside a screen |
| `routeIn` / `routeOut` | 260 / 200 ms | `AppPageTransitionsBuilder` |
| `sheetIn` / `sheetOut` | 300 / 220 ms | the change-password sheet |
| `easeOut` | cubic-bezier(.23, 1, .32, 1) | entrances and presses |
| `easeInOut` | cubic-bezier(.77, 0, .175, 1) | moving elements |

Exit is always shorter than entrance. A screen that takes as long to leave as it
did to arrive reads as hesitant.

## Pages

`AppPageTransitionsBuilder` replaces Android's zoom with a fade and an 8% rise,
animating opacity and transform only. iOS and macOS keep
`CupertinoPageTransitionsBuilder`, because the back-swipe depends on it. The
duration comes from the builder, so every `MaterialPageRoute` in the app —
including the three in `lib/main.dart` — is covered without touching a call site.

## Presses

`Pressable` is an `InkWell` inside an `AnimatedScale`: the ripple, focus ring,
keyboard activation and semantics are Material's, and the scale is the only
addition. Four surfaces use it — `AuthAction`, `AuthLink`, `WorkoutCard` and the
profile's account rows — where the whole card is the target.

The scale is driven by `onTapDown` / `onTapUp` / `onTapCancel`, not by
`onHighlightChanged`, because a highlight also fires on hover and focus. A
disabled surface gets no tap callbacks at all, so it neither scales nor flashes.

## Reduced motion

`MediaQuery.disableAnimationsOf(context)` is read in `Pressable` and in the page
builder, and `showChangePasswordSheet` passes `AnimationStyle.noAnimation` when
it is set. Movement is dropped, not the interaction: taps still work, pages
still change, and the sheet still opens.

## Deliberately not here

- **Hero transitions.** No screen has a shared element that survives the trip in
  a way that would explain itself; a flying thumbnail would be decoration.
- **Staggered entrances.** Lists arrive with data, and delaying rows makes a
  fast database look slow.
- **Skeletons and shimmer.** The stores are local and answer before a frame is
  painted; a skeleton would be a lie about waiting.
- **A cross-fade between tabs.** `AppShell` keeps every tab alive in an
  `IndexedStack` so scroll positions and form state survive a switch. A
  cross-fade would either rebuild them or fade a static stack for no reason.
- **A motion package.** The four behaviours above are framework widgets. Adding
  `flutter_animate`, `go_router` or a spring library would buy curves the app
  does not use and another dependency to cite.
