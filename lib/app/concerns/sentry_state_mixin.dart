import 'package:magic/magic.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Captures state errors and exceptions to Sentry automatically.
///
/// Overrides [setError] to report every error-state transition as a
/// Sentry message, and exposes [captureStateException] for ad-hoc
/// exception reporting with state-class context.
///
/// ## Usage
///
/// ```dart
/// class MonitorController extends MagicController
///     with MagicStateMixin<List<Monitor>>, SentryStateMixin<List<Monitor>> {
///   Future<void> load() async {
///     setLoading();
///     try {
///       final monitors = await Http.get('/monitors');
///       setSuccess(monitors);
///     } catch (e, st) {
///       captureStateException(e, st, operation: 'load');
///       setError('Failed to load monitors');
///     }
///   }
/// }
/// ```
mixin SentryStateMixin<T> on MagicStateMixin<T> {
  /// Reports [message] to Sentry as an error-level message, then delegates
  /// to [super.setError] to update reactive state as usual.
  @override
  void setError(String message) {
    Sentry.captureMessage(
      message,
      level: SentryLevel.error,
      withScope: (scope) {
        scope.setTag('state_class', runtimeType.toString());
      },
    );

    super.setError(message);
  }

  /// Captures an exception with state-class context tags.
  ///
  /// [operation] is an optional label (e.g. `'loadMonitors'`) added as a
  /// Sentry tag so errors can be filtered by the action that caused them.
  void captureStateException(
    Object error,
    StackTrace stackTrace, {
    String? operation,
  }) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('state_class', runtimeType.toString());

        if (operation != null) {
          scope.setTag('operation', operation);
        }
      },
    );
  }
}
