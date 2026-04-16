import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:playx_navigation/src/routes/playx_page.dart';

import '../binding/playx_binding.dart';
import '../models/playx_page_config.dart';
import '../models/playx_page_configuration.dart';
import '../models/playx_page_transition.dart';

/// A custom route class extending [GoRoute] that provides additional features
/// such as custom page transitions, route bindings, and page configuration settings.
///
/// The [PlayxRoute] class extends the [GoRoute] class to offer enhanced routing
/// capabilities, including custom animations for page transitions, configurable
/// settings for pages, and bindings for route-specific lifecycle events.
///
/// **Shell builder support:**
/// When [shellBuilder] is provided, the page's outer chrome (AppBar, Drawer,
/// Scaffold) is rendered immediately during navigation transitions. Only the
/// body content waits for the binding's `onEnter` to complete, preventing
/// blank frames during page transitions.
///
/// **Non-blocking initialization:**
/// Set [waitForBinding] to `false` to render the page content immediately while
/// `onEnter` runs in the background. The builder receives `isInitialized = false`
/// until the binding is ready.
///
/// **Example Usage:**
/// ```dart
/// // With shell builder — AppBar shows immediately:
/// PlayxRoute(
///   path: '/channels',
///   name: 'channels',
///   shellBuilder: (context, state, isInitialized, child) => Scaffold(
///     appBar: AppBar(title: Text('Channels')),
///     drawer: MyDrawer(),
///     body: child,
///   ),
///   builder: (context, state, isInitialized) => ChannelsListView(),
///   binding: ChannelsBinding(),
/// )
///
/// // Without shell — uses isInitialized to handle loading:
/// PlayxRoute(
///   path: '/profile',
///   name: 'profile',
///   builder: (context, state, isInitialized) {
///     if (!isInitialized) return ProfileSkeleton();
///     return ProfilePage();
///   },
///   binding: ProfileBinding(),
///   waitForBinding: false,
/// )
/// ```
///
/// **Parameters:**
/// - `path`: The URL path of the route, for example, `/profile`.
/// - `name`: An optional name for the route, which is useful for navigation and redirection.
/// - `builder`: A [PlayxRouteWidgetBuilder] that builds the widget for this route,
///   receiving the current context, state, and initialization status.
/// - `shellBuilder`: An optional [PlayxShellWidgetBuilder] that wraps the page
///   content with persistent chrome (AppBar, Drawer). Overrides global default.
/// - `transition`: Specifies the page transition animation to be used. Defaults to [PlayxPageTransition.cupertino].
/// - `pageConfiguration`: Configures various settings for the page, such as title and key. Defaults to [PlayxPageConfiguration()].
/// - `parentNavigatorKey`: An optional key for the parent navigator.
/// - `binding`: An optional [PlayxBinding] instance used to handle route-specific lifecycle events.
/// - `loadingWidget`: An optional widget shown while `onEnter` is executing. Overrides global default.
/// - `waitForBinding`: Whether to block the build on `onEnter`. `null` uses the global default.
/// - `initTransitionDuration`: Duration for crossfade animation between loading and content. `null` uses global default.
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
  ///
  /// Overrides the global [PlayxPageConfig.loadingWidget].
  /// Defaults to [SizedBox.shrink()] when neither route-level nor global is set.
  final Widget? loadingWidget;

  /// Optional shell builder for persistent page chrome (AppBar, Drawer, Scaffold).
  ///
  /// When provided, the shell is rendered **immediately** during navigation
  /// transitions. The `child` parameter passed to the shell builder contains
  /// either the actual page content (when initialized) or a loading widget
  /// (while `onEnter` is running).
  ///
  /// Overrides the global [PlayxPageConfig.shellBuilder].
  ///
  /// ```dart
  /// shellBuilder: (context, state, isInitialized, child) => Scaffold(
  ///   appBar: AppBar(title: Text('My Page')),
  ///   drawer: isInitialized ? MyDrawer() : null,
  ///   body: child,
  /// ),
  /// ```
  final PlayxShellWidgetBuilder? shellBuilder;

  /// Whether to block the page build until `onEnter` completes.
  ///
  /// - `null` (default): Use the global default from [PlayxPageConfig.waitForBinding].
  /// - `true`: Block the build — show loading widget or shell until `onEnter` completes.
  /// - `false`: Render content immediately — `onEnter` runs in the background,
  ///   and the builder receives `isInitialized = false` until ready.
  final bool? waitForBinding;

  /// Duration for the crossfade animation between the loading widget and
  /// the initialized page content.
  ///
  /// When set, an [AnimatedSwitcher] smoothly transitions from the loading
  /// state to the actual content after `onEnter` completes.
  ///
  /// - `null` (default): Use the global default from [PlayxPageConfig.initTransitionDuration].
  /// - [Duration.zero]: No animation (instant swap).
  /// - Any positive duration: Crossfade with that duration (e.g., `Duration(milliseconds: 300)`).
  final Duration? initTransitionDuration;

  PlayxRoute({
    required super.path,
    super.name,
    required PlayxRouteWidgetBuilder builder,
    this.transition = PlayxPageTransition.cupertino,
    this.pageConfiguration = const PlayxPageConfiguration(),
    super.parentNavigatorKey,
    this.binding,
    this.loadingWidget,
    this.shellBuilder,
    this.waitForBinding,
    this.initTransitionDuration,
    super.redirect,
    super.onExit,
    super.routes = const <RouteBase>[],
  }) : super(
          pageBuilder: (ctx, state) {
            return transition.buildPage(
              config: pageConfiguration,
              child: binding == null
                  ? builder(ctx, state, true)
                  : PlayxPage(
                      binding: binding,
                      state: state,
                      childBuilder: builder,
                      shellBuilder: shellBuilder,
                      loadingWidget: loadingWidget,
                      waitForBinding: waitForBinding,
                      initTransitionDuration: initTransitionDuration,
                    ),
              state: state,
            );
          },
        );
}
