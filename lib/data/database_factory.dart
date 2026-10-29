import 'database_factory_stub.dart'
    if (dart.library.io) 'database_factory_io.dart'
    as platform;

/// Gives sqflite a database factory on platforms where the plugin has none.
///
/// Android and iOS answer through the sqflite plugin, so this does nothing
/// there. A desktop build has no plugin, and without the FFI factory the first
/// read throws "databaseFactory not initialized" — the app then starts signed
/// out and cannot make an account, which looks like broken sign-in rather than
/// a missing platform implementation.
void usePlatformDatabaseFactory() => platform.usePlatformDatabaseFactory();
