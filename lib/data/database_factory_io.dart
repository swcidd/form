import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Installs the FFI factory on the desktop targets, and only there.
///
/// The check is by target rather than by `Platform.isLinux` so this file stays
/// free of `dart:io`; the conditional import already keeps it out of the web
/// build, and the mobile targets must keep the plugin's own factory.
void usePlatformDatabaseFactory() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      break;
  }
}
