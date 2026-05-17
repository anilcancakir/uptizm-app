import 'package:fluttersdk_artisan/artisan.dart';
import 'package:fluttersdk_dusk/dusk.dart';
import 'package:fluttersdk_mcp/mcp.dart';
import 'package:fluttersdk_telescope/telescope.dart';
import 'package:magic_tinker/magic_tinker.dart';

/// Artisan command providers registered by uptizm-app's bin/artisan.dart.
///
/// Each provider contributes a `<namespace>:*` command set to the unified
/// `artisan` binary. Magic-side providers (MagicArtisanProvider for make:*,
/// StarterArtisanProvider, NotificationsArtisanProvider) are V1.x; they
/// require magic + companion refactors not yet landed.
final List<ArtisanServiceProvider Function()> artisanProviders = [
  DuskArtisanProvider.new,
  TelescopeArtisanProvider.new,
  TinkerArtisanProvider.new,
  McpArtisanProvider.new,
];
