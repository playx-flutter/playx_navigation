import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'routes/playx_router.dart';

/// An abstract class that provides static methods for navigating within the
/// application using [GoRouter].
///
/// This class needs to be initialized by calling [PlayxNavigation.boot] before
/// using any of its methods. Alternatively, you can add the `PlayxNavigationBuilder`
/// widget to your widget tree.
abstract class PlayxNavigation {
  PlayxNavigation._();

  static PlayxRouter? _playxRouter;

  /// Gets the singleton instance of [PlayxRouter].
  ///
  /// Throws an exception if [PlayxNavigation] has not been initialized.
  static PlayxRouter get _router {
    if (_playxRouter == null) {
      throw Exception('PlayxNavigation is not initialized. '
          'Please ensure that PlayxNavigation.boot() has been called before using any PlayxNavigation methods,'
          ' or include the PlayxNavigationBuilder widget in your widget tree.');
    }
    return _playxRouter!;
  }

  /// Initializes [PlayxNavigation] with the given [GoRouter].
  ///
  /// This method must be called before using any other methods of [PlayxNavigation].
  static void boot({required GoRouter router}) {
    _playxRouter = PlayxRouter(router: router);
  }

  /// Gets the current [RouteMatch] object representing the current route in the
  /// navigation stack.
  static RouteMatch? get currentRoute => _router.currentRoute;

  /// Gets the name of the current route, if available.
  ///
  /// Returns `null` if there is no current route or if the route has no name.
  static String? get currentRouteName => currentRoute?.route.name;

  /// Adds a listener for route changes.
  ///
  /// The provided [listener] is called whenever the route changes.
  static void addRouteChangeListener(VoidCallback listener) {
    _router.addRouteChangeListener(listener);
  }

  /// Removes a previously added route change listener.
  ///
  /// The provided [listener] will no longer be called when the route changes.
  static void removeRouteChangeListener(VoidCallback listener) {
    _router.removeRouteChangeListener(listener);
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
  static void goToBranch({
    required int index,
    bool? initialLocation,
    required StatefulNavigationShell navigationShell,
  }) {
    return _router.goToBranch(
      index: index,
      navigationShell: navigationShell,
      initialLocation: initialLocation,
    );
  }

  /// Pushes a new route onto the navigation stack using a URI location.
  ///
  /// The [name] parameter specifies the name of the route, and the optional [extra]
  /// parameter can be used to pass additional data to the route.
  ///
  /// Returns a [Future] that completes with the result from the pushed route.
  ///
  /// Example usage:
  /// ```dart
  /// await PlayxNavigation.to('/details', extra: {'id': 1});
  /// ```
  static Future<T?> to<T>(
    String name, {
    Object? extra,
  }) async {
    return _router.to(
      name,
      extra: extra,
    );
  }

  /// Navigates to a new route, replacing all previous routes in the stack.
  ///
  /// The [name] parameter specifies the name of the new route, and the optional
  /// [extra] parameter can be used to pass additional data to the route.
  ///
  /// Example usage:
  /// ```dart
  /// await PlayxNavigation.offAll('/home', extra: {'clearHistory': true});
  /// ```
  static Future<void> offAll(
    String name, {
    Object? extra,
  }) async {
    return _router.offAll(
      name,
      extra: extra,
    );
  }

  /// Replaces the current route with a new route.
  ///
  /// The [name] parameter specifies the name of the new route, and the optional
  /// [extra] parameter can be used to pass additional data to the route.
  ///
  /// Example usage:
  /// ```dart
  /// await PlayxNavigation.offAndTo('/profile', extra: {'userId': 123});
  /// ```
  static Future<void> offAndTo(
    String name, {
    Object? extra,
  }) async {
    return _router.offAndTo(
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
  ///
  /// Example usage:
  /// ```dart
  /// await PlayxNavigation.toNamed('details', pathParameters: {'id': '1'});
  /// ```
  static Future<T?> toNamed<T>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    return _router.toNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Navigates to a named route, replacing all previous routes in the stack.
  ///
  /// The [name] parameter specifies the name of the new route. Additional
  /// parameters include [pathParameters], [queryParameters], and [extra] for
  /// passing data to the route.
  ///
  /// Example usage:
  /// ```dart
  /// await PlayxNavigation.offAllNamed('home');
  /// ```
  static Future<void> offAllNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    return _router.offAllNamed(
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
  ///
  /// Example usage:
  /// ```dart
  /// await PlayxNavigation.offAndToNamed('profile', pathParameters: {'userId': '123'});
  /// ```
  static Future<void> offAndToNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    return _router.offAndToNamed(
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
  ///
  /// Example usage:
  /// ```dart
  /// PlayxNavigation.pop('User closed dialog');
  /// ```
  static void pop<T extends Object?>([T? result]) {
    return _router.pop(result);
  }

  /// Returns `true` if there are two or more routes in the navigation stack that can be popped.
  ///
  /// Example usage:
  /// ```dart
  /// if (PlayxNavigation.canPop()) {
  ///   PlayxNavigation.pop();
  /// }
  /// ```
  static bool canPop() => _router.canPop();

  /// Refreshes the current route, effectively reloading the route.
  ///
  /// Example usage:
  /// ```dart
  /// PlayxNavigation.refresh();
  /// ```
  static void refresh() {
    return _router.refresh();
  }

  /// Restores the given [RouteMatchList] to the navigation stack.
  ///
  /// This method is useful for restoring the state of the navigation stack.
  ///
  /// Example usage:
  /// ```dart
  /// PlayxNavigation.restore(savedMatchList);
  /// ```
  static void restore(RouteMatchList matchList) {
    return _router.restore(matchList);
  }

  /// Generates a URI location string for a named route.
  ///
  /// The [name] parameter specifies the name of the route. Additional
  /// parameters include [pathParameters] and [queryParameters] for building
  /// the URI.
  ///
  /// This is useful for generating URIs to use in redirects or for other
  /// navigation-related purposes.
  ///
  /// Example usage:
  /// ```dart
  /// String location = PlayxNavigation.namedLocation('details', pathParameters: {'id': '1'});
  /// ```
  static String namedLocation(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) =>
      _router.namedLocation(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
      );
}
