import 'dart:async';

import 'package:ai_test_flutter/ai_test_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:magic/magic.dart';
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

  // V3: MCP-only single-channel via VM Service custom extensions.
  // The compile-time `kIsWeb && kDebugMode` outer guard lets dart2js prove
  // the entire branch dead in release, stripping AiTestPluginV3 + every
  // ext.aitest.* extension + RefRegistry + interceptor + log sink out of
  // the production bundle. AiTestPluginV3.install() registers all 19
  // ext.aitest.* RPCs idempotently (try/catch ArgumentError per call,
  // hot-restart safe). The host app must wrap its widget root in
  // RepaintBoundary(key: AiTestPluginV3.rootRepaintBoundaryKey, ...) so
  // the screenshot extension can call toImage(); the wrap below honors
  // that contract on both runApp branches (Sentry-wrapped and bare).
  if (kIsWeb && kDebugMode) {
    AiTestPluginV3.install();
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
            runApp(
              kIsWeb && kDebugMode
                  ? RepaintBoundary(
                      key: AiTestPluginV3.rootRepaintBoundaryKey,
                      child: app,
                    )
                  : app,
            );
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
    runApp(
      kIsWeb && kDebugMode
          ? RepaintBoundary(
              key: AiTestPluginV3.rootRepaintBoundaryKey,
              child: app,
            )
          : app,
    );
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
