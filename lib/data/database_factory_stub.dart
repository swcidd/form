/// No platform factory to install.
///
/// The web build reaches this file through the conditional import in
/// `database_factory.dart`. Persistence is not wired for the web target; this
/// keeps the import of the FFI package out of that build instead of failing it.
void usePlatformDatabaseFactory() {}
