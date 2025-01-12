import 'package:go_router/go_router.dart';
import 'package:playx_navigation/src/binding/playx_page_state.dart';
import 'package:playx_navigation/src/routes/playx_page.dart';

import '../binding/playx_binding.dart';
import '../models/playx_page_configuration.dart';
import '../models/playx_page_transition.dart';

/// A custom route class extending [GoRoute] that provides additional features
/// such as custom page transitions, route bindings, and page configuration settings.
///
/// The [PlayxRoute] class extends the [GoRoute] class to offer enhanced routing
/// capabilities, including custom animations for page transitions, configurable
/// settings for pages, and bindings for route-specific lifecycle events.
///
/// **Example Usage:**
/// ```dart
/// PlayxRoute(
///   path: '/profile',
///   name: 'profile',
///   builder: (BuildContext context, GoRouterState state) {
///     return ProfilePage(userId: state.pathParameters['userId']);
///   },
///   transition: PlayxPageTransition.fade,
///   pageConfiguration: PlayxPageConfiguration(
///     title: 'User Profile',
///   ),
///   binding: MyProfileBinding(),
/// );
/// ```
///
/// **Parameters:**
/// - `path`: The URL path of the route, for example, `/profile`.
/// - `name`: An optional name for the route, which is useful for navigation and redirection.
/// - `builder`: A function that builds the widget for this route, given the current context and state.
/// - `transition`: Specifies the page transition animation to be used. Defaults to [PlayxPageTransition.cupertino].
/// - `pageConfiguration`: Configures various settings for the page, such as title and key. Defaults to [PlayxPageConfiguration()].
/// - `parentNavigatorKey`: An optional key for the parent navigator.
/// - `binding`: An optional [PlayxBinding] instance used to handle route-specific lifecycle events.
/// - `redirect`: An optional callback function for custom redirection logic.
/// - `onExit`: An optional callback function for handling logic when the route is exited.
/// - `routes`: A list of nested subroutes for this route. Defaults to an empty list.
///
/// **Behavior:**
/// - **Page Transition:** The [transition] parameter allows for custom animations when transitioning between pages.
/// - **Page Configuration:** The [pageConfiguration] parameter enables customization of page settings, including title and unique key.
/// - **Route Binding:** The [binding] parameter allows for attaching a [PlayxBinding] to handle lifecycle events.
///   - `onEnter`: Invoked when the route is entered for the first time. For subroutes, this method is called each time the subroute is entered.
///   - `onExit`: Called when the route is exited. For subroutes, the `onExit` method of the main route is executed only when the main route is removed from the navigation stack.
///
/// **Custom Redirection:**
/// If a [redirect] callback is provided, it will handle redirection logic. If not provided, the default redirection behavior is applied.
///
/// **Route Lifecycle:**
/// - The `onEnter` method of the route's binding is executed when the route is entered for the first time or when navigating to the same route as the top route.
/// - The `onExit` method is executed when the route is exited. If a [binding] is provided, its `onExit` method is called based on the `shouldExecuteOnExit` flag.
class PlayxRoute extends GoRoute {
  /// An optional [PlayxBinding] instance used to handle route-specific lifecycle events.
  ///
  /// The [binding] allows you to attach custom logic that is executed when the route is entered or exited.
  /// - `onEnter`: This method is called when the route is entered for the first time.
  /// - `onExit`: This method is called when the route is exited.
  final PlayxBinding? binding;

  /// Specifies the page transition animation to be used.
  ///
  /// The [transition] determines the animation effect applied when navigating between pages for this route.
  /// Defaults to [PlayxPageTransition.cupertino]. Other options might include [PlayxPageTransition.material], [PlayxPageTransition.native], etc.
  final PlayxPageTransition transition;

  /// Configures various settings for the page.
  ///
  /// The [pageConfiguration] parameter allows you to set page-specific configurations such as title, key, and other properties.
  /// Or Add custom transitions, animations, and other page-specific settings.
  /// Defaults to [PlayxPageConfiguration()].
  final PlayxPageConfiguration pageConfiguration;

  PlayxRoute({
    required super.path,
    super.name,
    required GoRouterWidgetBuilder builder,
    this.transition = PlayxPageTransition.cupertino,
    this.pageConfiguration = const PlayxPageConfiguration(),
    super.parentNavigatorKey,
    this.binding,
    GoRouterRedirect? redirect,
    ExitCallback? onExit,
    super.routes = const <RouteBase>[],
  }) : super(
          redirect: (context, state) async {
            // Handle custom redirection logic if provided
            if (redirect != null) {
              return redirect(context, state);
            }
            if (binding == null) return null;

            final topRoute = state.topRoute;
            // Trigger onEnter when entering the page for the first time and when the top route is the same as the current route
            // We need to fire onEnter here so we can have access to the route state.
            if (topRoute == null || path == topRoute.path) {
              final pageState = binding.currentState;
              if (pageState == null || pageState == PlayxPageState.exit) {
                binding.onEnter(context, state);
                binding.currentState = PlayxPageState.enter;
              } else {
                binding.onReEnter(
                  context,
                  state,
                  true,
                );
                binding.currentState = PlayxPageState.reEnter;
              }
              binding.shouldExecuteOnExit = false;
            } else {}
            return null;
          },
          onExit: binding == null
              ? onExit
              : (context, state) async {
                  bool shouldExit = true;
                  if (onExit != null) {
                    shouldExit = await onExit(context, state);
                  }
                  binding.shouldExecuteOnExit = shouldExit;
                  return shouldExit;
                },
          pageBuilder: (ctx, state) {
            return transition.buildPage(
              config: pageConfiguration,
              child: binding == null
                  ? builder(ctx, state)
                  : PlayxPage(binding: binding, child: builder(ctx, state)),
              state: state,
            );
          },
        );
}
