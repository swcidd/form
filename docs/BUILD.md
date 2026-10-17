# Building FORM

Two builds matter: **debug**, for running against a device while working, and
**release**, for the APK that gets handed in or installed. They differ in more
than optimization flags, and one of them is signed with a key you have to make
yourself.

## Requirements

| Tool | Version |
| --- | --- |
| Flutter | ≥ 3.47.0 |
| Dart | ≥ 3.13.0 |
| Java (bundled with Android Studio) | 17 |
| Android SDK | as resolved by `flutter doctor` |

The Dart and Flutter floors are declared in `pubspec.yaml` and match the
resolved `pubspec.lock`, so `flutter pub get` fails loudly on an older SDK
instead of resolving a different set of packages than the one that was tested.

```bash
flutter doctor        # confirm the Android toolchain is complete
flutter pub get       # resolve dependencies against pubspec.lock
```

## Debug build

```bash
flutter run                    # on the connected device, hot reload enabled
flutter build apk --debug      # debug APK at build/app/outputs/flutter-apk/
```

Debug builds are signed with the Android debug keystore that every SDK install
generates at `~/.android/debug.keystore`. Nothing to configure, and nothing you
would want to ship: the key is present on every machine, so the signature
proves nothing about who built the app.

Debug builds also keep assertions on, skip tree-shaking, and — by default in
this project — fetch font files from the network at runtime.

## Release build

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

A release build compiles ahead-of-time, strips assertions, and signs with a key
of your own. Assertions off means a release build can behave differently from a
debug one — run the release APK on a device at least once before submitting it,
not just the debug build you have been testing in.

### Signing

`android/app/build.gradle.kts` reads signing material from
`android/key.properties`. **That file is gitignored, along with any `.jks` or
`.keystore`.** There are no secrets in the repository.

When `android/key.properties` is missing, the release build falls back to the
debug keys, so `flutter build apk --release` still produces a runnable APK on a
fresh clone or a CI box. That fallback APK is installable but not a distributable
release — it cannot be uploaded to a store and its signature is not yours.

To sign properly, create a keystore once (keep it and its passwords out of the
repository, and back the file up — losing it means you can never update the app
under the same identity):

```bash
keytool -genkey -v \
  -keystore ~/form-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias form
```

Then copy `android/key.properties.example` to `android/key.properties` and fill
in `storePassword`, `keyPassword`, `keyAlias`, and the absolute `storeFile` path.
The next `flutter build apk --release` picks it up automatically.

Verify what a build was signed with (`apksigner` ships with the Android SDK
build-tools, and the APK is verified with the v2 scheme, so the older
`keytool -printcert -jarfile` — which only understands v1/JAR signing — reports
"Not a signed jar file"):

```bash
"$ANDROID_HOME"/build-tools/*/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
```

A debug-signed APK prints `CN=Android Debug`:

```
Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
```

A properly signed one prints the alias and organization you entered above. The
same command with `-v` states which signature schemes verified — v2 is what
Android 7+ uses, so a release is fine without v1.

To read the package name and SDK levels a build was compiled with:

```bash
"$ANDROID_HOME"/build-tools/*/aapt2 dump badging \
  build/app/outputs/flutter-apk/app-release.apk | head -3
```

## App identity

| Field | Value | Where |
| --- | --- | --- |
| Display name | `FORM` | `android/app/src/main/AndroidManifest.xml` |
| Application ID | `com.swcidd.form` | `android/app/build.gradle.kts` |
| Namespace | `com.swcidd.form` | same, kept in step with the Kotlin source path |
| min / target / compile SDK | 24 / 36 / 36 | resolved from the Flutter toolchain |

The application ID is the app's permanent identity on a device and in a store.
Changing it later means a different installed app, so it is fixed now.

## Sanity check before submitting

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
```

Four commands, four green results. If the release build is signed with a real
key, `keytool -printcert` above is the fifth.
