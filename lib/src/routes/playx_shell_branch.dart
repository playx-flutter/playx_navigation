import 'package:flutter/cupertino.dart';
import 'package:playx_navigation/playx_navigation.dart';

/// A [PlayxShellBranch] is a [StatefulShellBranch] that is used to create a branch with a single route or multiple routes with [PlayxRoute]s.
class PlayxShellBranch<T extends Object> extends StatefulShellBranch {
  /// Creates a new [PlayxShellBranch] with a single route.
  ///
  /// Provide either [builder] or [initBuilder], but not both:
  /// - [builder]: Classic `(context, state)` — library manages loading state.
  /// - [initBuilder]: New `(context, state, isInitialized)` — user has full control.
  ///
  /// The [shellBuilder] wraps the page content with persistent chrome (AppBar, Drawer).
  /// The [waitForBinding] controls whether to block the build on `onEnter`.
  /// The [initTransitionDuration] sets the crossfade animation duration.
  /// These only apply when using [builder], not [initBuilder].
  ///
  /// Pass [controller] (and optionally [disposeController]) to give the
  /// branch's page its own controller of type [T]; see [PlayxRoute].
  PlayxShellBranch({
    super.navigatorKey,
    super.initialLocation,
    super.restorationScopeId,
    super.observers,
    super.preload = false,
    required String path,
    String? name,
    GoRouterWidgetBuilder? builder,
    PlayxRouteWidgetBuilder? initBuilder,
    PlayxPageTransition transition = PlayxPageTransition.cupertino,
    PlayxPageConfiguration pageConfiguration = const PlayxPageConfiguration(),
    GlobalKey<NavigatorState>? parentNavigatorKey,
    PlayxBinding? binding,
    PlayxControllerBuilder<T>? controller,
    void Function(T controller)? disposeController,
    Widget? loadingWidget,
    PlayxShellWidgetBuilder? shellBuilder,
    bool? waitForBinding,
    Duration? initTransitionDuration,
    List<PlayxGuard> guards = const <PlayxGuard>[],
    PlayxErrorWidgetBuilder? errorBuilder,
    Duration? enterTimeout,
    GoRouterRedirect? redirect,
    ExitCallback? onExit,
    List<RouteBase> routes = const [],
  })  : assert(
          builder != null || initBuilder != null,
          'Either builder or initBuilder must be provided.',
        ),
        assert(
          builder == null || initBuilder == null,
          'Cannot provide both builder and initBuilder. '
          'Use builder for library-managed loading, or initBuilder for full control.',
        ),
        super(routes: [
          PlayxRoute<T>(
            path: path,
            name: name,
            builder: builder,
            initBuilder: initBuilder,
            transition: transition,
            pageConfiguration: pageConfiguration,
            parentNavigatorKey: parentNavigatorKey,
            binding: binding,
            controller: controller,
            disposeController: disposeController,
            loadingWidget: loadingWidget,
            shellBuilder: shellBuilder,
            waitForBinding: waitForBinding,
            initTransitionDuration: initTransitionDuration,
            guards: guards,
            errorBuilder: errorBuilder,
            enterTimeout: enterTimeout,
            redirect: redirect,
            onExit: onExit,
            routes: routes,
          )
        ]);

  /// Creates a new [PlayxShellBranch] with multiple routes.
  ///
  /// The [routes] is a list of routes that this branch will handle.
  PlayxShellBranch.routes({
    super.navigatorKey,
    super.initialLocation,
    super.restorationScopeId,
    super.observers,
    super.preload = false,
    required List<PlayxRoute> routes,
  }) : super(routes: routes);
}
