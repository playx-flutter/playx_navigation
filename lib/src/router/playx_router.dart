import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  GoRouterState? get state => router.state;

  /// Gets the current [GoRoute] object representing the current route in the
  /// navigation stack.
  GoRoute? get currentRoute => state?.topRoute;

  /// Gets the name of the current route, if available.
  ///
  /// Returns `null` if there is no current route or if the route has no name.
  String? get currentRouteName => state?.name;

  /// Adds a listener for route changes.
  ///
  /// The provided [listener] is called whenever the route changes.
  void addRouteChangeListener(VoidCallback listener) {
    router.routerDelegate.addListener(listener);
  }

  /// Removes a previously added route change listener.
  ///
  /// The provided [listener] will no longer be called when the route changes.
  void removeRouteChangeListener(VoidCallback listener)

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
  {
    router.routerDelegate.removeListener(listener);
  }

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
