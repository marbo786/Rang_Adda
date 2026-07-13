// Platform-conditional export.
// On native platforms (Android, iOS, Windows, macOS, Linux) where dart:ffi
// is available, the real TFLite implementation is used.
// On Web (where dart:ffi is unavailable), the stub falls back to Medium bot.
export 'thulla_bot_ml_web.dart'
    if (dart.library.ffi) 'thulla_bot_ml_native.dart';
