import 'package:fluttersdk_artisan/artisan.dart';
import 'package:magic_tinker/cli.dart';

/// Artisan command providers registered by uptizm-app's `bin/artisan.dart`.
///
/// IMPORTANT: This file MUST stay pure-Dart (no Flutter imports). The
/// consumer-side `bin/artisan.dart` runs under `dart run` which cannot
/// load `dart:ui`. Each provider package exposes a `cli.dart` sub-barrel
/// that only re-exports the artisan-side surface (command classes +
/// provider), keeping the Flutter-side install entry (e.g. DuskPlugin,
/// TelescopePlugin, TinkerPlugin) separate.
///
/// Magic-side providers (MagicArtisanProvider, StarterArtisanProvider,
/// NotificationsArtisanProvider, etc.) will land here once each package
/// ships its own `cli.dart` sub-barrel. Until then this list registers
/// only the pure-Dart-compatible TinkerArtisanProvider so the consumer
/// wrapper boots without dragging Flutter into pub resolution.
final List<ArtisanServiceProvider Function()> artisanProviders = [
  TinkerArtisanProvider.new,
];
