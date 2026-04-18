import 'package:magic/magic.dart';
import '../app/providers/app_service_provider.dart';
import '../app/providers/policy_service_provider.dart';
import '../app/providers/route_service_provider.dart';
import 'package:magic_starter/magic_starter.dart';

/// Application Configuration.
///
/// Evaluated lazily through [configFactories] in `main.dart` so environment
/// variables resolved by `Env.load()` are in scope. The `providers` list is
/// ordered — core framework providers boot first, domain providers last, and
/// `MagicStarterServiceProvider` always registers AFTER `AppServiceProvider`
/// so that starter can consume our overridden auth + navigation config.
Map<String, dynamic> get appConfig => {
  'app': {
    'name': env('APP_NAME', 'My App'),
    'env': env('APP_ENV', 'production'),
    'debug': env('APP_DEBUG', false),
    'key': env('APP_KEY'),
    'providers': [
      (app) => RouteServiceProvider(app),
      (app) => CacheServiceProvider(app),
      (app) => DatabaseServiceProvider(app),
      (app) => LaunchServiceProvider(app),
      (app) => LocalizationServiceProvider(app),
      (app) => NetworkServiceProvider(app),
      (app) => VaultServiceProvider(app),
      (app) => BroadcastServiceProvider(app),
      (app) => AppServiceProvider(app),
      (app) => AuthServiceProvider(app),
      (app) => PolicyServiceProvider(app),
      (app) => MagicStarterServiceProvider(app),
    ],
  },
};
