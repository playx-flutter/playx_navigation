import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../binding/playx_binding.dart';
import '../routes/playx_route.dart';

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

/// Runs [PlayxBinding.redirect], but only when the destination route uses
/// [binding] (route-level redirects also run for sub-routes).
class PlayxBindingGuard extends PlayxGuard {
  /// The binding whose [PlayxBinding.redirect] is run.
  final PlayxBinding binding;

  /// Creates a guard for [binding].
  const PlayxBindingGuard(this.binding);

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final top = state.topRoute;
    if (top is! PlayxRoute || !identical(top.binding, binding)) return null;
    return binding.redirect(context, state);
  }
}

/// Combines [guards] and an optional [redirect] into a single
/// [GoRouterRedirect]. Guards run first, in order; the first non-null result
/// wins. Returns [redirect] unchanged when there are no guards.
///
/// The chain stays synchronous as long as every guard answers synchronously,
/// so navigation isn't delayed by a frame for routes whose guards don't need
/// to await anything.
GoRouterRedirect? composeGuards(
  List<PlayxGuard> guards,
  GoRouterRedirect? redirect,
) {
  if (guards.isEmpty) return redirect;
  return (BuildContext context, GoRouterState state) {
    FutureOr<String?> run(int index) {
      if (index == guards.length) return redirect?.call(context, state);
      final result = guards[index].redirect(context, state);
      if (result is Future<String?>) {
        return result.then((location) => location ?? run(index + 1));
      }
      return result ?? run(index + 1);
    }

    return run(0);
  };
}
