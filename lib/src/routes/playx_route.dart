import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
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
///   - `onEnter`: Invoked when the route's page widget first mounts (via `initState`).
///   - `onExit`: Called when the route's page widget is disposed (truly removed from the tree).
///   - `onHidden`: Called when another route takes the foreground while this route stays in the stack.
///   - `onReEnter`: Called when this route returns to the foreground after being hidden.
///
/// **Custom Redirection:**
/// If a [redirect] callback is provided, it will handle redirection logic independently of binding lifecycle.
///
/// **Route Lifecycle:**
/// The binding lifecycle is managed through the [PlayxPage] widget lifecycle
/// and the [PlayxNavigationBuilder] route-change listener — no longer through redirect callbacks.
class PlayxRoute extends GoRoute {
  /// An optional [PlayxBinding] instance used to handle route-specific lifecycle events.
  ///
  /// The [binding] allows you to attach custom logic that is executed at different
  /// stages of the route's lifecycle:
  /// - `onInitApp`: Called once during app initialization.
  /// - `onEnter`: Called when the route's page widget first mounts.
  /// - `onHidden`: Called when another route covers this route.
  /// - `onReEnter`: Called when this route returns to the foreground.
  /// - `onExit`: Called when the route's page widget is disposed.
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

  /// An optional widget that is displayed while the [binding]'s `onEnter` is being initialized.
  /// Defaults to [SizedBox.shrink()].
  final Widget? loadingWidget;

  PlayxRoute({
    required super.path,
    super.name,
    required GoRouterWidgetBuilder builder,
    this.transition = PlayxPageTransition.cupertino,
    this.pageConfiguration = const PlayxPageConfiguration(),
    super.parentNavigatorKey,
    this.binding,
    this.loadingWidget,
    super.redirect,
    super.onExit,
    super.routes = const <RouteBase>[],
  }) : super(
          pageBuilder: (ctx, state) {
            return transition.buildPage(
              config: pageConfiguration,
              child: binding == null
                  ? builder(ctx, state)
                  : PlayxPage(
                      binding: binding,
                      state: state,
                      loadingWidget: loadingWidget,
                      child: builder(ctx, state),
                    ),
              state: state,
            );
          },
        );
}
