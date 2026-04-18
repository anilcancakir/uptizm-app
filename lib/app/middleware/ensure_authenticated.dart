import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

/// Middleware that redirects unauthenticated users to the login page.
///
/// Use this in auth-only route groups:
///
/// ```dart
/// MagicRoute.group(
///   middleware: [EnsureAuthenticated()],
///   routes: () { /* protected routes */ },
/// );
/// ```
class EnsureAuthenticated extends MagicMiddleware {
  /// Gates the protected route. Guests redirect to the login route without
  /// invoking [next]; authenticated users fall through.
  @override
  Future<void> handle(void Function() next) async {
    if (!Auth.check()) {
      MagicRoute.to(MagicStarterConfig.loginRoute());
      return;
    }
    next();
  }
}
