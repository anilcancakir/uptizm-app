import 'package:fluttersdk_artisan/artisan.dart';

/// Artisan command providers registered by uptizm-app's `bin/artisan.dart`.
///
/// IMPORTANT: This file MUST stay pure-Dart (no Flutter imports). The
/// consumer-side `bin/artisan.dart` runs under `dart run` which cannot
/// load `dart:ui`. Each provider package exposes a `cli.dart` sub-barrel
/// that only re-exports the artisan-side surface (command classes +
/// provider), keeping the Flutter-side install entry (e.g. DuskPlugin,
/// TelescopePlugin) separate.
///
/// Tinker is a builtin of fluttersdk_artisan now — no provider needed for
/// it. Magic-side providers (MagicArtisanProvider, StarterArtisanProvider,
/// NotificationsArtisanProvider, etc.) will land here once each package
/// ships its own `cli.dart` sub-barrel.
final List<ArtisanServiceProvider Function()> artisanProviders = [];
