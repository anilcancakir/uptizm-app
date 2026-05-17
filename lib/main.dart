import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttersdk_dusk/dusk.dart';
import 'package:fluttersdk_telescope/telescope.dart';
import 'package:magic/magic.dart';
import 'package:magic_tinker/magic_tinker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config/app.dart';
import 'config/auth.dart';
import 'config/broadcasting.dart';
import 'config/cache.dart';
import 'config/database.dart';
import 'config/logging.dart';
import 'config/magic_starter.dart';
import 'config/network.dart';
import 'config/routing.dart';
import 'config/sentry.dart';
import 'config/view.dart';
import 'config/wind.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // fluttersdk dev-tooling ecosystem (V1 local-first per /ac:execute --auto
  // local-first variant; pub.dev publish + magic adapters happen V1.x).
  // `kDebugMode` is the only gate: dart2js (web) + dart2native (desktop +
  // mobile AOT) tree-shake the entire branch out of release builds.
  // - DuskPlugin: gesture/snap/screenshot/wait/find extensions (ext.dusk.*)
  // - TelescopePlugin: HTTP capture (via adapter) + log + exception (ext.telescope.*)
  // - TinkerPlugin: VM Service evaluate sentinel (ext.tinker.evaluate)
  // Framework-side plugins register VM service extensions (no Magic dep).
  // Safe to install before Magic.init(). The Magic-side adapters move
  // below Magic.init() — they consume Magic.make<NetworkDriver>('network')
  // and need the IoC container fully bound first.
  if (kDebugMode) {
    DuskPlugin.install();
    TelescopePlugin.install();
    TinkerPlugin.install();
    WindDuskIntegration.install();
  }

  // Register SentryNavigatorObserver BEFORE Magic.init() — router is built
  // during boot(), so observers must be added before that. Unconditional
  // because env() isn't loaded yet; the observer is a no-op when Sentry
  // has no DSN.
  MagicRouter.instance.addObserver(
    SentryNavigatorObserver(
      setRouteNameAsTransaction: true,
      routeNameExtractor: (settings) {
        if (settings == null) return null;
        final name = settings.name ?? '/';
        final normalized = name.replaceAllMapped(
          RegExp(
            r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
            r'|[0-9A-Za-z]{26}',
          ),
          (_) => ':id',
        );
        return RouteSettings(name: normalized, arguments: settings.arguments);
      },
    ),
  );

  await Magic.init(
    configFactories: [
      () => appConfig,
      () => routingConfig,
      () => viewConfig,
      () => authConfig,
      () => databaseConfig,
      () => networkConfig,
      () => cacheConfig,
      () => loggingConfig,
      () => broadcastingConfig,
      () => magicStarterConfig,
      () => sentryConfig,
    ],
  );

  // Magic-side fluttersdk dev-tooling adapters. Run AFTER Magic.init()
  // because MagicHttpFacadeAdapter resolves NetworkDriver from the IoC
  // container, MagicDuskIntegration's enrichers reference MagicRouter,
  // and MagicTinkerIntegration seeds Tinker hooks Magic facades.
  if (kDebugMode) {
    MagicDuskIntegration.install();
    MagicTelescopeIntegration.install();
    MagicTinkerIntegration.install();
  }

  final sentryDsn = Config.get<String>('sentry.dsn', '') ?? '';
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = Config.get<String>('sentry.environment', 'local');

        const sentryRelease = String.fromEnvironment('SENTRY_RELEASE');
        if (sentryRelease.isNotEmpty) {
          options.release = sentryRelease;
        }
        const sentryDist = String.fromEnvironment('SENTRY_DIST');
        if (sentryDist.isNotEmpty) {
          options.dist = sentryDist;
        }

        options.sampleRate = Config.get<double>('sentry.sample_rate', 1.0);

        options.tracesSampleRate = Config.get<double>(
          'sentry.traces_sample_rate',
          1.0,
        );
        options.enableAutoPerformanceTracing = true;

        options.replay.sessionSampleRate = Config.get<double>(
          'sentry.replay_session_sample_rate',
          0.1,
        );
        options.replay.onErrorSampleRate = Config.get<double>(
          'sentry.replay_error_sample_rate',
          1.0,
        );
        options.replay.quality = SentryReplayQuality.medium;

        options.attachScreenshot = true;
        options.screenshotQuality = SentryScreenshotQuality.medium;
        options.attachViewHierarchy = true;

        if (!kIsWeb) {
          options.anrEnabled = true;
          options.enableNativeCrashHandling = true;
          options.enableAppHangTracking = true;
          options.appHangTimeoutInterval = const Duration(seconds: 2);
          options.enableFramesTracking = true;
          options.profilesSampleRate = Config.get<double>(
            'sentry.profiles_sample_rate',
            1.0,
          );
        }

        options.enableAutoNativeBreadcrumbs = true;
        options.enableUserInteractionBreadcrumbs = true;
        options.maxBreadcrumbs = 100;

        options.enableAutoSessionTracking = true;

        options.privacy.maskAllText = true;
        options.privacy.maskAllImages = true;
        options.sendDefaultPii = false;

        options.tracePropagationTargets.add(
          Config.get<String>('network.drivers.api.base_url', 'localhost') ??
              'localhost',
        );

        options.debug =
            Config.get<String>('sentry.environment', 'local') != 'production';
      },
      appRunner: () {
        return runZonedGuarded(
          () {
            _configureErrorVisibility();
            final Widget app = SentryWidget(
              child: MagicApplication(title: 'Uptizm', windTheme: windTheme),
            );
            runApp(kDebugMode ? RepaintBoundary(child: app) : app);
          },
          (exception, stackTrace) {
            Sentry.captureException(exception, stackTrace: stackTrace);
          },
        );
      },
    );
  } else {
    _configureErrorVisibility();
    final Widget app = MagicApplication(title: 'Uptizm', windTheme: windTheme);
    runApp(kDebugMode ? RepaintBoundary(child: app) : app);
  }
}

/// Overrides [ErrorWidget.builder] in non-production environments so
/// rendering errors show the red error widget instead of silent gray blanks.
void _configureErrorVisibility() {
  final isProduction =
      Config.get<String>('sentry.environment', 'local') == 'production';
  if (!isProduction) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return ErrorWidget(details.exception);
    };
  }
}
