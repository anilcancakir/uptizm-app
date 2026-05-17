import 'dart:io';

import 'package:app/config/artisan.dart';
import 'package:fluttersdk_artisan/artisan.dart';

/// uptizm-app consumer-side artisan dispatcher.
///
/// Loads 9 builtin commands from fluttersdk_artisan + expands the providers
/// list from lib/config/artisan.dart (4 fluttersdk providers in V1; magic
/// adapter providers added V1.x).
Future<void> main(List<String> args) async {
  try {
    final registry = ArtisanRegistry();
    registry.registerAll(
      _builtinCommands(registry),
      providerName: 'fluttersdk_artisan',
    );
    for (final factory in artisanProviders) {
      final provider = factory();
      registry.registerProvider(provider);
    }
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
      DoctorCommand(),
      ListCommand(registry),
      HelpCommand(registry),
      MakeCommandCommand(),
    ];
