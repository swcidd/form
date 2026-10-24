# Accounts in FORM

FORM runs without a server. That is a design decision, not a missing piece: the
app is the whole product, the training data never leaves the device, and the
demo works with the radio off. Accounts are kept anyway, because "who is this
training for" is the question a training app has to answer the moment two people
share a phone.

This file is the design of that. It is also the measurement behind the iteration
count in `lib/auth/password_hasher.dart`.

## The seam

Everything above `AuthRepository` is written as if the accounts lived somewhere
else:

```
screens ─── AuthProvider ─── AuthRepository ─┬── LocalAuthRepository  (SQLite, shipped)
                                             └── a server, if there ever is one
```

| Piece | File | Owns |
| --- | --- | --- |
| `AuthRepository` | `lib/auth/auth_repository.dart` | The verbs: create, sign in, continue offline, sign out, change password, delete, restore |
| `LocalAuthRepository` | `lib/auth/local_auth_repository.dart` | Accounts and the session in the app's SQLite file |
| `PasswordHasher` | `lib/auth/password_hasher.dart` | Deriving and checking a verifier |
| `AuthProvider` | `lib/providers/auth_provider.dart` | What the UI knows: `AuthStatus` and `busy` |
| `Session` | `lib/models/session.dart` | `userId` — the one fact the rest of the app reads |

`AuthRepository` returns a `Session` for sign-in and restore, and a
`SignUpOutcome` for a sign-up: either `SignedUp(session)` or
`ConfirmationSent(email)`. The second case is the one a server-backed store
needs. Supabase's default sign-up creates the account, sends a link and returns
**no session** until that link is followed; a store forced to return a `Session`
would have to pretend somebody is signed in. The create-account screen switches
on the outcome, so the same code turns into "check your inbox" instead of
opening the app.

`AuthException` carries an `AuthFailure`, a closed set: `invalidEmail`,
`weakPassword`, `emailInUse`, `invalidCredentials`, `unavailable` and
`emailNotConfirmed`. The first four are answers a device can give on its own;
the last two are the vocabulary a network store needs — a request that could not
be made, and an account whose address has not been confirmed. None of them
distinguishes an address nobody has from a password that is wrong: both are
`invalidCredentials`, so the refusal cannot be used to ask whether an address is
registered. Signing in as an unknown address spends the same time as a real one,
by verifying against a decoy verifier, for the same reason.

Failures are thrown rather than stored. The same failure reads differently on a
sign-in screen than in a settings sheet ("that password is not right" against
"that is not your current password"), so the words belong to the screen
(`AuthMessages`) and the repository hands it the reason.

**A server would go in at `AuthRepository` and nothing else would change.** The
provider, the screens, the tests and the shapes are all written against the
interface. That is what the seam buys, and it is why this is not a Firebase
implementation with a local fallback bolted on: the fallback *is* the first
implementation.

### The slot Supabase Auth would fill

The seam was checked against Supabase's API rather than imagined, because
"ready for a backend" means the verbs already answer in the shapes that backend
uses:

| Seam | Supabase | What the app already does with it |
| --- | --- | --- |
| `createAccount` | `signUp(email:, password:, data: {'display_name': …, 'age': …, 'height_cm': …, 'weight_kg': …})`; a null session means the confirmation mail is on its way | returns `ConfirmationSent`, the account step becomes "check your inbox" |
| `signIn` | `signInWithPassword`; `email_not_confirmed` maps to `emailNotConfirmed` | the same banner vocabulary, no new screen |
| `restoreSession` | `currentSession`, refreshed by the client | the gate opens on the right account before the first frame |
| `changePassword` | `signInWithPassword` with the typed current password, then `updateUser(password:)` | the same sheet, including "that is not your current password" |
| `deleteAccount` | an RPC that removes the auth user, then the local wipe | rows still go in one transaction, scoped by `userId` |
| `continueOffline` | nothing to call — the device account is local by design | the demo keeps working with the radio off |

Supabase keeps its own access and refresh tokens inside its client, so `Session`
stays the facts the app actually reads: `userId`, `issuedAt`, `email` and
`displayName`. No token is written to the app's own tables, and no screen would
have to learn what one is. The sign-up measurements are seeded into the local
profile, where the profile screen reads and edits them.

Two things this deliberately does *not* do: ship a project URL or key (there is
no project, and the assignment rules out credentials in a public repository),
and pretend a confirmed-email flow exists locally. The local store answers
`SignedUp` every time, because the device is the authority on its own accounts
and there is no inbox for a link to arrive in.


## Why not Firebase yet

Deferred, not rejected. Deciding against it for this submission:

- no console access to provision a project, and
- `google-services.json` in a public repository is a credential in a public
  repository, which the assignment's own rules rule out, and
- the demo runs on a phone with no reliable wifi, and an app whose sign-in
  fails without a network reads as broken rather than as offline.

## The flow

```
launch
  └── restore the session          (behind the splash: it decides what opens)
        ├── nobody      → Welcome ─┬─ Continue offline  → device account ("local")
        │                          ├─ Log in            → a named account
        │                          └─ Create account    → a named account
        │                               ├─ SignedUp            → the app
        │                               └─ ConfirmationSent    → "check your inbox"
        └── somebody    → the app
              └── Profile → Account → Change password | Sign out | Delete account
```

The welcome screen is skippable and says so: "Your training stays on this
device." Continue offline writes a session naming `Session.deviceUserId`
(`'local'`), which is the same account an upgraded install already has. Creating
an account starts empty — the app ships no sample data, so a new account is a
new account.

A gate, not a redirect, sits between the two halves (`lib/main.dart`). Redirecting
would leave the sign-in screens on the stack behind the app, and signing out
would then reveal the last of them instead of starting over. Two windows, each
with its own key (`'sign-in'` and `'app'`), so the navigator is replaced rather
than reused.

## Passwords

Stored: a PBKDF2-HMAC-SHA256 verifier, `pbkdf2-sha256$iterations$salt$key`, with
a 16-byte per-account salt from `Random.secure()` and a 32-byte key. The
iteration count is written into the string, so raising the default later does not
invalidate verifiers written at the old cost.

Measured on the development machine (AMD Ryzen 5 5600H, Dart JIT in the test
VM), signing in costs:

| Iterations | Median | Runs (ms) |
| --- | --- | --- |
| 12 000 (shipped) | 105 ms | 103, 104, 105, 105, 133 |
| 40 000 | 254 ms | 204, 227, 254, 287, 321 |

A release build on a phone is slower than this and is the figure that matters;
12 000 is chosen so a low-end phone stays under about a second, which is the
point of the work — deliberately expensive per guess, still tolerable per
sign-in. The app is honest about what this buys: it protects the *secret*, not
the training data, which sits in the same file in the clear and is readable on a
rooted device. Anything stronger means the password never reaching the device,
which is the server-shaped slot above.

Two consequences of that cost:

- The derivation runs off the frame, via `compute`. Synchronously it is worse
  than slow: the frame that would draw the loading state never gets to run
  before the work starts, so a sign-in looks like nothing happening until it is
  over.
- The verification comparison is constant time, so how much of a candidate
  matched is not observable.

## Ownership

Every row belongs to an account, and the account is part of what identifies the
row rather than a column on the side of it:

| Table | Key |
| --- | --- |
| `workouts` | `(userId, id)` |
| `exercise_logs` | `(userId, workoutId, position)` |
| `sets` | `(userId, workoutId, logIndex, position)` |
| `profile` | `userId` |
| `saved_exercises` | `(userId, id)` |

Each account numbers its own sessions from one, so two accounts both have a
`w1` and neither is the other's. The children carry `userId` too, so a cascade
lands on one account's rows.

`WorkoutRepository` is scoped at construction — `WorkoutRepository(app, userId: …)`
is "the store as one account sees it" — so no query in it can forget whose rows
it is reading, and `AppDatabase.accountScopedTables` is the schema's own list of
what has an owner, which is what deleting an account walks.

Migration v4 rebuilds rather than alters, because SQLite cannot change a primary
key in place and the key on the id alone means the second account to create a
workout silently fails to save it. Rows written before accounts existed belong to
the device account, so an upgraded install opens on its own training instead of
an empty app. v6 adds `age` to the profile, defaulting to zero for rows written
before the question existed.

## Deliberately not here

| Not built | Why |
| --- | --- |
| Apple and Google sign-in | Inert without a credential provider; they would be buttons that fail. |
| "Forgot password?" | A local account has no recovery channel. The honest version of that button is "delete the account and start again", which the profile already offers, and which says what it takes. |
| Email verification, password reset by email, sync | All of them are the server's job, and there is no server. |
| Encryption of the training data | Out of scope for this submission, and worth saying plainly rather than implying the account protects it. |

The sign-up is four steps, in the design's order: name, age, measurements, then
the credentials. Height is stored in centimetres and weight in kilograms; the
unit buttons convert what is typed, so a profile does not remember which unit it
was given in. The same fields edit age, height and weight from the profile's
Body section. The confirmation-password field is still not there: it is a second
entry for a value the app is about to hash anyway. The change-password sheet
follows the same rule — current password and new password, no second copy — so
the app asks for a password the same way everywhere.

## Tests

| File | Covers |
| --- | --- |
| `test/password_hasher_test.dart` | RFC 2898 vectors, salt uniqueness, cost stored in the verifier |
| `test/auth_repository_test.dart` | Real file, real SQLite: create, sign in, refusals, session round trip, delete |
| `test/auth_provider_test.dart` | Status transitions, `busy` held in a `finally`, failures passed on |
| `test/auth_screens_test.dart` | The screens and the gate, driven through the UI, including a sign-up that needs confirming |
| `test/session_store_test.dart` | The app builds the store for the account the session names |
| `test/data/database_test.dart` | v1→v6, v3→v6 on a genuinely old-shaped file, v5→v6, and per-account partitioning |
| `test/profile_screen_test.dart` | Editing the body, and the account section: who it is, change the password, sign out, delete asking first |
