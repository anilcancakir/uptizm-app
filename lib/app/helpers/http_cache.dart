import 'package:flutter/foundation.dart';
import 'package:magic/magic.dart';

/// In-flight GET dedup wrapper around [Http].
///
/// Coalesces concurrent identical GETs into a single real request: while a
/// request is in flight, subsequent callers with the same `method + url +
/// sorted(query)` receive the **same** Future. The entry is cleared the
/// moment the underlying future completes (success or failure), so this is
/// purely a concurrency coalescer, not a response cache.
///
/// Use on read-only polling endpoints where two controllers may fire the
/// same GET in the same frame. Leave mutating verbs (POST/PUT/DELETE)
/// untouched.
class HttpCache {
  HttpCache._();

  static final Map<String, Future<MagicResponse>> _inFlight = {};

  /// Deduped GET. Mirrors [Http.get] signature.
  static Future<MagicResponse> get(
    String url, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    final key = _keyFor(url, query);
    final existing = _inFlight[key];
    if (existing != null) return existing;
    final future = Http.get(url, query: query, headers: headers);
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  /// Clear the in-flight map. Tests only.
  @visibleForTesting
  static void reset() => _inFlight.clear();

  static String _keyFor(String url, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return url;
    final keys = query.keys.toList()..sort();
    final serialized = keys.map((k) => '$k=${query[k]}').join('&');
    return '$url?$serialized';
  }
}
