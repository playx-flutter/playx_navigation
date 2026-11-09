import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/playx_route.dart';

/// A class that simplifies navigation using the [GoRouter] by providing
/// convenient methods for route management and navigation.
class PlayxRouter {
  /// A key to access the root navigator's state.
  final GlobalKey<NavigatorState> rootNavigatorKey;

  /// The [GoRouter] instance used for navigation.
  final GoRouter router;

  /// Creates a new instance of [PlayxRouter].
  ///
  /// The [router] parameter is required and initializes the [rootNavigatorKey]
  /// with the [GoRouter]'s configuration.
  PlayxRouter({
    required this.router,
  }) : rootNavigatorKey = router.configuration.navigatorKey;

  /// Gets the current [GoRouterState] object representing the current state of the
  /// navigation stack.
  GoRouterState get state => router.state;

  /// Like [state], but returns `null` instead of throwing when there is no
  /// matched route (e.g. while go_router shows its error page for an unknown
  /// location).
  GoRouterState? get stateOrNull {
    if (router.routerDelegate.currentConfiguration.matches.isEmpty) {
      return null;
    }
    return router.state;
  }

  /// Gets the current [GoRoute] object representing the current route in the
  /// navigation stack, or `null` when there is no matched route.
  GoRoute? get currentRoute => stateOrNull?.topRoute;

  /// Gets the name of the current route, if available.
  ///
  /// Returns `null` if there is no current route or if the route has no name.
  String? get currentRouteName => stateOrNull?.name;

  /// Adds a listener for route changes.
  ///
  /// The provided [listener] is called whenever the route changes.
  void addRouteChangeListener(VoidCallback listener) {
    router.routerDelegate.addListener(listener);
  }

  /// Removes a previously added route change listener.
  ///
  /// The provided [listener] will no longer be called when the route changes.
  void removeRouteChangeListener(VoidCallback listener) {
    router.routerDelegate.removeListener(listener);
  }

  /// Navigate to the current location of the branch at the provided index of
  /// [StatefulShellRoute].
  ///
  /// The [index] specifies the branch to navigate to, and [navigationShell]
  /// manages the stateful navigation. The optional [initialLocation] parameter
  /// determines whether to navigate to the initial location of the branch.
  ///
  /// When navigating to a new branch, it's recommended to use the goToBranch
  /// method, as doing so makes sure the last navigation state of the
  /// Navigator for the branch is restored.
  void goToBranch({
    required int index,
    required StatefulNavigationShell navigationShell,
    bool? initialLocation,
  }) {
    return navigationShell.goBranch(
      index,
      initialLocation:
          initialLocation ?? (index == navigationShell.currentIndex),
    );
  }

  /// Pushes a new route onto the navigation stack using a URI location.
  ///
  /// The [name] parameter specifies the name of the route, and the optional [extra]
  /// parameter can be used to pass additional data to the route.
  ///
  /// Returns a [Future] that completes with the result from the pushed route.
  Future<T?> to<T>(
    String name, {
    Object? extra,
  }) async {
    return router.push(
      name,
      extra: extra,
    );
  }

  /// Navigates to a new route, replacing all previous routes in the stack.
  ///
  /// The [name] parameter specifies the name of the new route, and the optional
  /// [extra] parameter can be used to pass additional data to the route.
  Future<void> offAll(
    String name, {
    Object? extra,
  }) async {
    return router.go(
      name,
      extra: extra,
    );
  }

  /// Replaces the current route with a new route.
  ///
  /// The [name] parameter specifies the name of the new route, and the optional
  /// [extra] parameter can be used to pass additional data to the route.
  Future<void> offAndTo(
    String name, {
    Object? extra,
  }) async {
    return router.replace(
      name,
      extra: extra,
    );
  }

  /// Pushes a named route onto the navigation stack.
  ///
  /// The [name] parameter specifies the name of the route. Additional parameters
  /// include [pathParameters], [queryParameters], and [extra] for passing data to
  /// the route.
  ///
  /// Returns a [Future] that completes with the result from the pushed route.
  Future<T?> toNamed<T>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    return router.pushNamed(name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra);
  }

  /// Navigates to a named route, replacing all previous routes in the stack.
  ///
  /// The [name] parameter specifies the name of the new route. Additional
  /// parameters include [pathParameters], [queryParameters], and [extra] for
  /// passing data to the route.
  Future<void> offAllNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    return router.goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Replaces the current route with a named route.
  ///
  /// The [name] parameter specifies the name of the new route. Additional
  /// parameters include [pathParameters], [queryParameters], and [extra] for
  /// passing data to the route.
  Future<void> offAndToNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    return router.replaceNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Pops the top-most route off the navigation stack.
  ///
  /// The optional [result] parameter can be provided to pass a result back to the
  /// previous route.
  void pop<T extends Object?>([T? result]) {
    return router.pop(result);
  }

  /// Pops the top-most route off the navigation stack.
  bool maybePop<T extends Object?>([T? result]) {
    if (canPop()) {
      router.pop(result);
      return true;
    }
    return false;
  }

  /// Pops the top-most route if possible, otherwise navigates to [location].
  ///
  /// Useful for "back" buttons on web: after a refresh, a typed URL or a deep
  /// link there may be nothing to pop.
  void popOrGo<T extends Object?>(
    String location, {
    T? result,
    Object? extra,
  }) {
    if (canPop()) {
      router.pop(result);
    } else {
      router.go(location, extra: extra);
    }
  }

  /// Pops the top-most route if possible, otherwise navigates to the named
  /// route [name].
  void popOrGoNamed<T extends Object?>(
    String name, {
    T? result,
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    if (canPop()) {
      router.pop(result);
    } else {
      router.goNamed(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );
    }
  }

  /// The location [back] goes to when there is nothing to pop, or `null`.
  ///
  /// Uses the current route's [PlayxRoute.parentLocation] if it returns a
  /// value, otherwise the nearest shorter path that matches a route
  /// (`/jobs/5/edit` → `/jobs/5` → `/jobs`). The automatic parent never falls
  /// back to `/`, so tab roots such as `/jobs` have no parent unless one is
  /// set explicitly.
  String? get parentLocation {
    final state = stateOrNull;
    return state == null ? null : parentOf(state);
  }

  /// The parent location of the page described by [state], or `null`.
  ///
  /// The route's [PlayxRoute.parentLocation] if it returns a value, otherwise
  /// the nearest shorter path that matches a route. Never `/`.
  String? parentOf(GoRouterState state) {
    final top = state.topRoute;
    if (top is PlayxRoute) {
      final explicit = top.parentLocation?.call(state);
      if (explicit != null) return explicit;
    }
    final segments = Uri.parse(state.matchedLocation)
        .pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    while (segments.length > 1) {
      segments.removeLast();
      final candidate = '/${segments.join('/')}';
      if (!router.configuration.findMatch(Uri.parse(candidate)).isError) {
        return candidate;
      }
    }
    return null;
  }

  /// Builds the [GoRouterState] of the page [location] would show, without
  /// navigating (redirects are not run). Returns `null` if no route matches.
  GoRouterState? stateFor(String location) {
    final matches = router.configuration.findMatch(Uri.parse(location));
    if (matches.isError || matches.matches.isEmpty) return null;
    return _buildState(matches, matches.last);
  }

  /// Whether [location] is the root page of a shell branch (the first page
  /// inside its innermost shell route).
  bool isShellBranchRoot(String location) {
    final matchList = router.configuration.findMatch(Uri.parse(location));
    if (matchList.isError || matchList.matches.isEmpty) return false;
    var matches = matchList.matches;
    var inShell = false;
    while (true) {
      final last = matches.last;
      if (last is ShellRouteMatch) {
        matches = last.matches;
        inShell = true;
        continue;
      }
      return inShell && matches.length == 1;
    }
  }

  /// The states of the pages in the current page stack, bottom to top
  /// (the current shell branch plus pages pushed above it).
  List<GoRouterState> get pageStack {
    final configuration = router.routerDelegate.currentConfiguration;
    final states = <GoRouterState>[];
    void visit(List<RouteMatchBase> matches) {
      for (final match in matches) {
        if (match is ShellRouteMatch) {
          visit(match.matches);
        } else if (match is ImperativeRouteMatch) {
          states.add(_buildState(match.matches, match));
        } else if (match is RouteMatch) {
          states.add(_buildState(configuration, match));
        }
      }
    }

    visit(configuration.matches);
    return states;
  }

  /// Pops until the page with [pageKey] is on top.
  ///
  /// Returns `false` (and does nothing) if that page is not in [pageStack].
  bool popToPage(LocalKey pageKey) {
    final stack = pageStack;
    if (!stack.any((state) => state.pageKey == pageKey)) return false;
    for (var i = 0; i < stack.length; i++) {
      if (stateOrNull?.pageKey == pageKey || !canPop()) break;
      router.pop();
    }
    return stateOrNull?.pageKey == pageKey;
  }

  /// Pops until the page showing [location] is on top.
  ///
  /// Only the path of [location] is compared (not query parameters or
  /// fragments), and the page closest to the top wins. Returns `true` if that
  /// page is now on top. If no page in the stack shows [location], nothing is
  /// popped and `false` is returned, unless [orGo] is set, which then goes to
  /// [location] and returns `true`.
  bool popUntil(String location, {bool orGo = false}) {
    final path = Uri.parse(location).path;
    final target = pageStack.reversed
        .where((state) => state.matchedLocation == path)
        .firstOrNull;
    if (target != null) return popToPage(target.pageKey);
    if (!orGo) return false;
    router.go(location);
    return true;
  }

  /// Like [popUntil], for the named route [name].
  bool popUntilNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    bool orGo = false,
  }) {
    return popUntil(
      namedLocation(name, pathParameters: pathParameters),
      orGo: orGo,
    );
  }

  GoRouterState _buildState(RouteMatchList list, RouteMatch match) {
    return GoRouterState(
      router.configuration,
      uri: list.uri,
      matchedLocation: match.matchedLocation,
      name: match.route.name,
      path: match.route.path,
      fullPath: list.fullPath,
      pathParameters: list.pathParameters,
      extra: list.extra,
      pageKey: match.pageKey,
      topRoute: match.route,
    );
  }

  /// Whether [back] can do something: pop, or go to a [parentLocation].
  bool get canGoBack => canPop() || parentLocation != null;

  /// Pops the top-most route if possible, otherwise goes to the current
  /// page's [parentLocation].
  ///
  /// Returns `false` if there was nothing to pop and no parent.
  bool back<T extends Object?>([T? result]) {
    if (canPop()) {
      router.pop(result);
      return true;
    }
    final parent = parentLocation;
    if (parent == null) return false;
    router.go(parent);
    return true;
  }

  /// Returns `true` if there is at least two or more route can be pop.
  bool canPop() => router.canPop();

  /// Refresh the current route.
  void refresh() {
    return router.refresh();
  }

  /// Restore the RouteMatchList
  void restore(RouteMatchList matchList) {
    return router.restore(matchList);
  }

  /// Get a location from route name and parameters.
  /// This is useful for redirecting to a named location.
  String namedLocation(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) =>
      router.namedLocation(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
      );
}
