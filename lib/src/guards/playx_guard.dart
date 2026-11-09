import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A guard that decides whether a route may be entered.
///
/// Attach guards to a route with [PlayxRoute.guards]. They run in order before
/// the route's own `redirect`; the first guard that returns a location
/// redirects there. Returning `null` lets navigation continue.
///
/// Guards on a route also apply to its sub-routes.
///
/// ```dart
/// class AuthGuard extends PlayxGuard {
///   const AuthGuard();
///
///   @override
///   FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
///     return AuthService.isLoggedIn ? null : '/login';
///   }
/// }
///
/// PlayxRoute(
///   path: '/account',
///   guards: [AuthGuard()],
///   builder: (context, state) => AccountPage(),
/// )
/// ```
abstract class PlayxGuard {
  const PlayxGuard();

  /// Creates a guard from a [GoRouterRedirect]-style callback.
  const factory PlayxGuard.from(GoRouterRedirect redirect) = _CallbackGuard;

  /// Returns the location to redirect to, or `null` to allow navigation.
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}

class _CallbackGuard extends PlayxGuard {
  final GoRouterRedirect _redirect;

  const _CallbackGuard(this._redirect);

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _redirect(context, state);
}

/// Combines [guards] and an optional [redirect] into a single
/// [GoRouterRedirect]. Guards run first, in order; the first non-null result
/// wins. Returns `null` when there is nothing to run.
GoRouterRedirect? composeGuards(
  List<PlayxGuard> guards,
  GoRouterRedirect? redirect,
) {
  if (guards.isEmpty) return redirect;
  return (BuildContext context, GoRouterState state) async {
    for (final guard in guards) {
      final location = await guard.redirect(context, state);
      if (location != null) return location;
    }
    // The redirect context is owned by go_router and valid for this call.
    // ignore: use_build_context_synchronously
    return redirect?.call(context, state);
  };
}
