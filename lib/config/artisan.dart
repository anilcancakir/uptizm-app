import 'package:fluttersdk_artisan/artisan.dart';
import 'package:fluttersdk_dusk/dusk.dart';
import 'package:fluttersdk_mcp/mcp.dart';
import 'package:fluttersdk_telescope/telescope.dart';
import 'package:magic/magic.dart';
import 'package:magic_deeplink/magic_deeplink.dart';
import 'package:magic_notifications/magic_notifications.dart';
import 'package:magic_social_auth/magic_social_auth.dart';
import 'package:magic_starter/magic_starter.dart';
import 'package:magic_tinker/magic_tinker.dart';

/// Artisan command providers registered by uptizm-app's bin/artisan.dart.
///
/// Each provider contributes a `<namespace>:*` command set to the unified
/// `artisan` binary. Order is presentation-only; ArtisanRegistry fails fast
/// on collisions, so namespace clashes surface immediately at registration.
final List<ArtisanServiceProvider Function()> artisanProviders = [
  MagicArtisanProvider.new,
  StarterArtisanProvider.new,
  NotificationsArtisanProvider.new,
  DeeplinkArtisanProvider.new,
  SocialAuthArtisanProvider.new,
  DuskArtisanProvider.new,
  TelescopeArtisanProvider.new,
  TinkerArtisanProvider.new,
  McpArtisanProvider.new,
];
