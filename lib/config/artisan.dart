import 'package:fluttersdk_artisan/artisan.dart';

/// Third-party command providers registered alongside the auto-discovered
/// commands from `lib/app/commands/`.
///
/// You do NOT list app-level commands here — drop a `.dart` file under
/// `lib/app/commands/` (or run `artisan make:command Foo`) and it auto-
/// registers via `lib/app/commands/_index.g.dart`.
///
/// Use this list for ServiceProvider-shipped commands from external pub
/// packages (`fluttersdk_dusk`, `fluttersdk_telescope`, `magic`,
/// `magic_starter`, ...). Add entries once each package ships a pure-Dart
/// `cli.dart` sub-barrel.
///
/// Pure-Dart only — no Flutter imports. The wrapper runs under `dart run`,
/// which cannot load `dart:ui`.
final List<ArtisanServiceProvider Function()> artisanProviders =
    <ArtisanServiceProvider Function()>[];
