import 'dart:io';

import 'package:app/app/commands/_index.g.dart' as auto;
import 'package:fluttersdk_artisan/artisan.dart';
import 'package:fluttersdk_dusk/cli.dart';
import 'package:fluttersdk_telescope/telescope.dart';

/// uptizm-app consumer-side artisan dispatcher.
///
/// Two registration paths:
///   1. App-level commands — every `ArtisanCommand` subclass under
///      `lib/app/commands/` is auto-discovered via the generated
///      `_index.g.dart` (kept fresh by `make:command` and
///      `commands:refresh`). ZERO config.
///   2. Third-party packages — uncomment the imports + registerProvider
///      lines below as you add pub packages that ship a `cli.dart`
///      sub-barrel (`fluttersdk_dusk`, `fluttersdk_telescope`,
///      `fluttersdk_mcp`, `magic`, `magic_starter`, ...).
Future<void> main(List<String> args) async {
  try {
    final registry = ArtisanRegistry();
    registry.registerAll(
      _builtinCommands(registry),
      providerName: 'fluttersdk_artisan',
    );
    registry.registerAll(auto.commands, providerName: 'app');

    // Third-party package providers — uncomment as needed.
    registry.registerProvider(DuskArtisanProvider());
    registry.registerProvider(TelescopeArtisanProvider());
    // registry.registerProvider(McpArtisanProvider());
    // registry.registerProvider(MagicArtisanProvider());
    // registry.registerProvider(StarterArtisanProvider());
    // registry.registerProvider(NotificationsArtisanProvider());
    // registry.registerProvider(DeeplinkArtisanProvider());
    // registry.registerProvider(SocialAuthArtisanProvider());

    final app = ArtisanApplication(registry: registry);
    exit(await app.dispatch(args));
  } on ArtisanCommandCollisionException catch (e) {
    stderr.writeln('Fatal: $e');
    exit(2);
  } catch (e, s) {
    stderr.writeln('Unexpected error: $e');
    stderr.writeln(s);
    exit(3);
  }
}

List<ArtisanCommand> _builtinCommands(ArtisanRegistry registry) =>
    <ArtisanCommand>[
      StartCommand(),
      StopCommand(),
      StatusCommand(),
      LogsCommand(),
      RestartCommand(),
      ReloadCommand(),
      HotRestartCommand(),
      DoctorCommand(),
      ListCommand(registry),
      HelpCommand(registry),
      MakeCommandCommand(),
      CommandsRefreshCommand(),
      TinkerCommand(),
    ];
