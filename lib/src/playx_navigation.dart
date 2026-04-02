import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart' as flutter_web_plugins;
import 'package:go_router/go_router.dart';

import 'router/playx_router.dart';
import 'routes/playx_route.dart';
import 'binding/playx_binding.dart';

/// An abstract class that provides static methods for navigating within the
/// application using [GoRouter].
///
/// This class needs to be initialized by calling [PlayxNavigation.boot] before
/// using any of its methods. Alternatively, you can add the `PlayxNavigationBuilder`
/// widget to your widget tree.
///
/// You can await [PlayxNavigation.ensureInitialized] anywhere in your app to
/// wait for the navigation system to finish booting and all [PlayxBinding.onInitApp]
/// methods to complete.
abstract class PlayxNavigation {
  PlayxNavigation._();

  static PlayxRouter? _playxRouter;

  static Completer<void>? _initCompleter;

  static final List<PlayxBinding> _bindings = [];

  /// Returns an unmodifiable list of all [PlayxBinding] instances discovered
  /// in the route tree during [boot].
  ///
  /// This list is populated after [boot] completes and includes every unique
  /// binding attached to a [PlayxRoute] in the router's configuration.
  static List<PlayxBinding> get bindings => List.unmodifiable(_bindings);

  /// Finds and returns the first [PlayxBinding] of the specified type [T]
  /// from the discovered bindings.
  ///
  /// Throws a [StateError] if no binding of type [T] is found.
  ///
  /// ### Example:
  /// ```dart
  /// final splashBinding = PlayxNavigation.findBinding<SplashBinding>();
  /// ```
  static T findBinding<T extends PlayxBinding>() {
    return _bindings.firstWhere(
      (binding) => binding is T,
      orElse: () => throw StateError(
        'No PlayxBinding of type $T found. '
        'Ensure a route with this binding is registered in the router.',
      ),
    ) as T;
  }

  /// Finds and returns the first [PlayxBinding] of the specified type [T]
  /// from the discovered bindings, or `null` if no match is found.
  ///
  /// ### Example:
  /// ```dart
  /// final binding = PlayxNavigation.findBindingOrNull<SplashBinding>();
  /// if (binding != null) {
  ///   // Use the binding.
  /// }
  /// ```
  static T? findBindingOrNull<T extends PlayxBinding>() {
    final match = _bindings.whereType<T>().firstOrNull;
    return match;
  }

  /// A [Future] that completes when [PlayxNavigation.boot] has finished,
  /// including the invocation of all [PlayxBinding.onInitApp] methods.
  ///
  /// Use this to gate logic that depends on the navigation system being fully
  /// initialized, for example in splash screens or startup flows:
  ///
  /// ```dart
  /// await PlayxNavigation.ensureInitialized;
  /// // Safe to use navigation and any dependencies registered in onInitApp.
  /// ```
  ///
  /// If [boot] has not been called yet, this getter returns a [Future] that
  /// will complete once [boot] finishes.
  /// If [boot] has already completed, the returned [Future] resolves immediately.
  static Future<void> get ensureInitialized {
    _initCompleter ??= Completer<void>();
    return _initCompleter!.future;
  }

  /// Whether the navigation system has been fully initialized.
  ///
  /// Returns `true` after [boot] has completed (including all
  /// [PlayxBinding.onInitApp] invocations). Returns `false` otherwise.
  static bool get isInitialized =>
      _initCompleter != null && _initCompleter!.isCompleted;

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
  ///
  /// When called, it automatically discovers all [PlayxBinding] instances
  /// attached to [PlayxRoute]s in the router's route tree and invokes their
  /// [PlayxBinding.onInitApp] methods, ensuring app-level dependencies are
  /// registered before any route lifecycle events are triggered.
  ///
  /// After boot completes, [ensureInitialized] resolves and [isInitialized]
  /// returns `true`.
  static Future<void> boot({required GoRouter router}) async {
    // Reset the completer and bindings for fresh initialization (supports re-boot).
    _initCompleter = Completer<void>();
    _bindings.clear();
    try {
      _playxRouter = PlayxRouter(router: router);
      await _initializeBindings(router);
      _initCompleter!.complete();
    } catch (e, s) {
      _initCompleter!.completeError(e, s);
      rethrow;
    }
  }

  /// Recursively walks the [GoRouter] route tree, collects all unique
  /// [PlayxBinding] instances, stores them, and calls [PlayxBinding.onInitApp] on each.
  static Future<void> _initializeBindings(GoRouter router) async {
    final discoveredBindings = <PlayxBinding>{};
    _collectBindings(router.configuration.routes, discoveredBindings);
    _bindings.addAll(discoveredBindings);
    for (final binding in _bindings) {
      await binding.onInitApp();
    }
  }

  /// Recursively collects all [PlayxBinding] instances from a list of routes.
  static void _collectBindings(
    List<RouteBase> routes,
    Set<PlayxBinding> bindings,
  ) {
    for (final route in routes) {
      if (route is PlayxRoute && route.binding != null) {
        bindings.add(route.binding!);
      }
      // Recurse into sub-routes
      if (route is GoRoute) {
        _collectBindings(route.routes, bindings);
      } else if (route is ShellRoute) {
        _collectBindings(route.routes, bindings);
      } else if (route is StatefulShellRoute) {
        for (final branch in route.branches) {
          _collectBindings(branch.routes, bindings);
        }
      }
    }
  }

  /// Sets up navigation for web applications.
  /// Allows for using path-based URLs and enables URL-based imperative APIs.
  static void setupWeb({
    bool usePathUrlStrategy = true,
    bool optionURLReflectsImperativeAPIs = true,
  }) {
    if (kIsWeb) {
      GoRouter.optionURLReflectsImperativeAPIs =
          optionURLReflectsImperativeAPIs;
      if (usePathUrlStrategy) {
        flutter_web_plugins.usePathUrlStrategy();
      }
    }
  }

  /// Returns the [GoRouter] instance used for navigation.
  static GoRouter get goRouter => _router.router;

  /// Gets the current [GoRouterState] object representing the current state of the
  /// navigation stack.
  static GoRouterState? get currentState => _router.state;

  /// Gets the current [RouteMatch] object representing the current route in the
  /// navigation stack.
  static GoRoute? get currentRoute => _router.currentRoute;

  /// Gets the name of the current route, if available.
  ///
  /// Returns `null` if there is no current route or if the route has no name.
  static String? get currentRouteName => currentRoute?.name;

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

  /// Pops the top-most route off the navigation stack.
  /// Returns `true` if the route was popped successfully.
  /// Returns `false` if there are no routes to pop.
  static bool maybePop<T extends Object?>([T? result]) {
    return _router.maybePop(result);
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

  /// Gets the root navigator key for the application.
  static GlobalKey<NavigatorState> get rootNavigatorKey =>
      _router.rootNavigatorKey;

  /// Gets the current [BuildContext] for the application's root navigator.
  static BuildContext? get navigationContext => rootNavigatorKey.currentContext;

  void dispose() {
    _playxRouter = null;
  }
}
