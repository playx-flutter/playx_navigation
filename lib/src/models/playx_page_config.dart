import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../routes/playx_page.dart' show PlayxScope;

/// Builder function for route content that includes initialization state.
///
/// Unlike [GoRouterWidgetBuilder], this builder exposes [isInitialized] so
/// the route widget can react to the binding's `onEnter` completion state.
///
/// - [context]: The [BuildContext] of the route.
/// - [state]: The [GoRouterState] containing metadata about the current route.
/// - [isInitialized]: Whether the binding's `onEnter` has completed.
///   Always `true` when no binding is attached.
typedef PlayxRouteWidgetBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
  bool isInitialized,
);

/// Builder function for a page's persistent shell (AppBar, Drawer, Scaffold).
///
/// The shell is rendered **immediately** during navigation transitions, avoiding
/// blank frames. The [child] parameter contains either the actual page content
/// (when initialized) or a loading widget (while `onEnter` is running).
///
/// This allows the page's outer chrome (AppBar, Drawer, bottom bar) to be
/// visible throughout the transition animation, while only the body area
/// shows a loading state.
///
/// - [context]: The [BuildContext] of the route.
/// - [state]: The [GoRouterState] containing metadata about the current route.
/// - [isInitialized]: Whether the binding's `onEnter` has completed.
/// - [child]: The content widget — either the page body or a loading placeholder.
typedef PlayxShellWidgetBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
  bool isInitialized,
  Widget child,
);

/// Builder function for the widget shown when a binding's `onEnter` fails
/// (throws) or exceeds its timeout.
///
/// - [context]: The [BuildContext] of the route.
/// - [state]: The [GoRouterState] containing metadata about the current route.
/// - [error]: The error thrown by `onEnter` (a [TimeoutException] on timeout).
/// - [stackTrace]: The stack trace of the error.
/// - [retry]: Call to run the binding's `onEnter` again.
typedef PlayxErrorWidgetBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
  Object error,
  StackTrace stackTrace,
  VoidCallback retry,
);

/// Registers or unregisters a route controller of type [T] in an external
/// registry (e.g. GetX). See [PlayxPageConfig.registerController].
typedef PlayxControllerRegistrar = void Function<T extends Object>(
  T controller,
  PlayxScope scope,
);

/// Finds a page's controller of type [T] in an external registry (e.g. GetX),
/// or returns `null`. See [PlayxPageConfig.findController].
typedef PlayxControllerFinder = T? Function<T extends Object>(
  PlayxScope scope,
);

/// Global configuration for [PlayxPage] behavior.
///
/// Provide this to [PlayxNavigationBuilder] to set defaults for all routes.
/// Individual route settings (on [PlayxRoute]) override these globals.
///
/// ### Example:
/// ```dart
/// PlayxNavigationBuilder(
///   router: myRouter,
///   config: PlayxPageConfig(
///     loadingWidget: Center(child: CircularProgressIndicator()),
///     waitForBinding: false,
///     shellBuilder: (context, state, isInitialized, child) => Scaffold(
///       appBar: AppBar(title: Text('My App')),
///       body: child,
///     ),
///   ),
///   builder: (context) => MyApp(),
/// )
/// ```
class PlayxPageConfig {
  /// Default widget shown while a binding's `onEnter` is executing.
  ///
  /// Used when a route doesn't specify its own `loadingWidget`.
  /// Defaults to [SizedBox.shrink()] when not provided.
  final Widget? loadingWidget;

  /// Whether routes should block their build on `onEnter` completion by default.
  ///
  /// When `true` (default), routes show a loading widget until `onEnter` completes.
  /// When `false`, routes render their content immediately and `onEnter` runs in
  /// the background. The builder receives `isInitialized = false` until ready.
  ///
  /// Individual routes can override this via [PlayxRoute.waitForBinding].
  final bool waitForBinding;

  /// Default shell builder applied to all routes that don't specify their own.
  ///
  /// When provided, every route with a binding will render this shell immediately
  /// during navigation, wrapping either the page content (when initialized) or
  /// a loading widget (while `onEnter` is running).
  ///
  /// Individual routes can override this via [PlayxRoute.shellBuilder].
  final PlayxShellWidgetBuilder? shellBuilder;

  /// Default duration for the crossfade animation between the loading widget
  /// and the initialized page content.
  ///
  /// When set, an [AnimatedSwitcher] with a fade transition is applied to
  /// smoothly transition from the loading state to the actual content.
  ///
  /// Set to `null` or [Duration.zero] to disable the animation (no transition).
  /// Individual routes can override this via [PlayxRoute.initTransitionDuration].
  final Duration? initTransitionDuration;

  /// Default widget builder shown when a binding's `onEnter` throws or times out.
  ///
  /// When `null` (and the route doesn't specify one), the error is reported
  /// through [FlutterError.reportError] and the loading state is kept.
  ///
  /// Individual routes can override this via [PlayxRoute.errorBuilder].
  final PlayxErrorWidgetBuilder? errorBuilder;

  /// Default maximum time to wait for a binding's `onEnter` to complete.
  ///
  /// When exceeded, it is treated as an error with a [TimeoutException].
  /// `null` (default) means no timeout.
  ///
  /// Individual routes can override this via [PlayxRoute.enterTimeout].
  final Duration? enterTimeout;

  /// Called with the route's controller type [T] right after a
  /// `PlayxRoute<T>(controller: ...)` controller is created, to register it in
  /// an external registry so `Get.find<T>()`, `GetBuilder<T>`, etc. keep
  /// working.
  ///
  /// ```dart
  /// registerController: <T extends Object>(T controller, PlayxScope scope) =>
  ///     Get.put<T>(controller, tag: scope.id),
  /// ```
  ///
  /// Tagging with `scope.id` keeps stacked pages of the same type apart;
  /// without a tag, `Get.find<T>()` works anywhere, but stacked pages of the
  /// same type share one registration.
  final PlayxControllerRegistrar? registerController;

  /// Called with the route's controller type [T] right before a route
  /// controller is disposed. Mirror of [registerController].
  ///
  /// ```dart
  /// unregisterController: <T extends Object>(T controller, PlayxScope scope) =>
  ///     Get.delete<T>(tag: scope.id),
  /// ```
  final PlayxControllerRegistrar? unregisterController;

  /// Used by `PlayxView<T>` and `context.controller<T>()` when the page's
  /// scope has no [T], e.g. when a binding registers controllers in GetX:
  ///
  /// ```dart
  /// findController: <T extends Object>(PlayxScope scope) =>
  ///     Get.isRegistered<T>(tag: scope.id) ? Get.find<T>(tag: scope.id) : null,
  /// ```
  final PlayxControllerFinder? findController;

  /// Creates a [PlayxPageConfig] with the specified defaults.
  const PlayxPageConfig({
    this.loadingWidget,
    this.waitForBinding = true,
    this.shellBuilder,
    this.initTransitionDuration,
    this.errorBuilder,
    this.enterTimeout,
    this.registerController,
    this.unregisterController,
    this.findController,
  });
}

/// An [InheritedWidget] that provides [PlayxPageConfig] to descendant widgets.
///
/// This is used internally by [PlayxNavigationBuilder] to propagate global
/// configuration down to [PlayxPage] instances.
class PlayxPageConfigProvider extends InheritedWidget {
  /// The global page configuration.
  final PlayxPageConfig config;

  const PlayxPageConfigProvider({
    super.key,
    required this.config,
    required super.child,
  });

  /// Retrieves the nearest [PlayxPageConfig] from the widget tree, or `null`
  /// if no [PlayxPageConfigProvider] is found.
  static PlayxPageConfig? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PlayxPageConfigProvider>()
        ?.config;
  }

  /// Like [of], but doesn't register a dependency, so it is safe to call from
  /// `initState` and from async callbacks.
  static PlayxPageConfig? read(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<PlayxPageConfigProvider>()
        ?.config;
  }

  @override
  bool updateShouldNotify(PlayxPageConfigProvider oldWidget) {
    return config != oldWidget.config;
  }
}
