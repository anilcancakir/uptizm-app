import 'package:magic/magic.dart';

import '../kernel.dart';
import '../../routes/app.dart';
import 'package:magic_starter/magic_starter.dart';

/// Route Service Provider.
///
/// Registers the HTTP kernel and application routes.
class RouteServiceProvider extends ServiceProvider {
  RouteServiceProvider(super.app);

  /// Registers the middleware kernel synchronously during bootstrap so
  /// named middleware are resolvable before any route definition runs.
  @override
  void register() {
    registerKernel();
  }

  /// Registers Magic Starter's auth / profile / team / notification route
  /// groups and then the application's own routes. Order matters: starter
  /// routes must exist first so their named paths can be referenced inside
  /// `registerAppRoutes()`.
  @override
  Future<void> boot() async {
    // Register application route definitions.
    registerMagicStarterAuthRoutes();
    registerMagicStarterProfileRoutes();
    registerMagicStarterTeamRoutes();
    registerMagicStarterNotificationRoutes();
    registerAppRoutes();
  }
}
