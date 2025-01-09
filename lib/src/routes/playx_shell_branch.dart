import 'package:flutter/cupertino.dart';
import 'package:playx_navigation/playx_navigation.dart';

/// A [PlayxShellBranch] is a [StatefulShellBranch] that is used to create a branch with a single route or multiple routes with [PlayxRoute]s.
class PlayxShellBranch extends StatefulShellBranch {
  /// Creates a new [PlayxShellBranch] with a single route.
  ///
  /// The [path] is the route path that this branch will handle.
  /// The [name] is the name of the route.
  /// The [builder] is the widget builder for the route.
  /// The [transition] is the page transition for the route.
  /// The [pageConfiguration] is the page configuration for the route.
  /// The [parentNavigatorKey] is the parent navigator key.
  /// The [binding] is the binding for the route.
  /// The [redirect] is the redirect callback for the route.
  /// The [onExit] is the exit callback for the route.
  PlayxShellBranch({
    super.navigatorKey,
    super.initialLocation,
    super.restorationScopeId,
    super.observers,
    super.preload = false,
    required String path,
    String? name,
    required GoRouterWidgetBuilder builder,
    PlayxPageTransition transition = PlayxPageTransition.cupertino,
    PlayxPageConfiguration pageConfiguration = const PlayxPageConfiguration(),
    GlobalKey<NavigatorState>? parentNavigatorKey,
    PlayxBinding? binding,
    GoRouterRedirect? redirect,
    ExitCallback? onExit,
    List<RouteBase> routes = const [],
  }) : super(routes: [
          PlayxRoute(
            path: path,
            name: name,
            builder: builder,
            transition: transition,
            pageConfiguration: pageConfiguration,
            parentNavigatorKey: parentNavigatorKey,
            binding: binding,
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
