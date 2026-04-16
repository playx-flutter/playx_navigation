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
/// **Two builder modes:**
///
/// 1. **Standard builder** (`builder`): Uses the classic `(context, state)` signature.
///    The library automatically manages loading/content switching using
///    [loadingWidget], [shellBuilder], [waitForBinding], and [initTransitionDuration].
///
/// 2. **Init-aware builder** (`initBuilder`): Uses `(context, state, isInitialized)`.
///    The user receives the initialization state and takes full control of
///    what to render. Shell builder, loading widget, and other auto-management
///    features are not applied.
///
/// Only one of [builder] or [initBuilder] should be provided.
///
/// **Shell builder support (standard builder only):**
/// When [shellBuilder] is provided, the page's outer chrome (AppBar, Drawer,
/// Scaffold) is rendered immediately during navigation transitions. Only the
/// body content waits for the binding's `onEnter` to complete, preventing
/// blank frames during page transitions.
///
/// **Example Usage:**
/// ```dart
/// // Standard builder — library manages loading:
/// PlayxRoute(
///   path: '/channels',
///   name: 'channels',
///   builder: (context, state) => ChannelsListView(),
///   binding: ChannelsBinding(),
///   shellBuilder: (context, state, isInitialized, child) => Scaffold(
///     appBar: AppBar(title: Text('Channels')),
///     body: child,
///   ),
/// )
///
/// // Init-aware builder — user handles everything:
/// PlayxRoute(
///   path: '/profile',
///   name: 'profile',
///   initBuilder: (context, state, isInitialized) {
///     if (!isInitialized) return ProfileSkeleton();
///     return ProfilePage();
///   },
///   binding: ProfileBinding(),
/// )
/// ```
///
/// **Parameters:**
/// - `path`: The URL path of the route, for example, `/profile`.
/// - `name`: An optional name for the route, which is useful for navigation and redirection.
/// - `builder`: A [GoRouterWidgetBuilder] — classic `(context, state)` builder.
///   The library automatically manages loading and content switching.
/// - `initBuilder`: A [PlayxRouteWidgetBuilder] — receives `(context, state, isInitialized)`.
///   The user controls what to render based on initialization state.
/// - `shellBuilder`: An optional [PlayxShellWidgetBuilder] that wraps the page
///   content with persistent chrome (AppBar, Drawer). Only applies with [builder].
/// - `transition`: Specifies the page transition animation. Defaults to [PlayxPageTransition.cupertino].
/// - `pageConfiguration`: Configures page settings such as title and key. Defaults to [PlayxPageConfiguration()].
/// - `parentNavigatorKey`: An optional key for the parent navigator.
/// - `binding`: An optional [PlayxBinding] for route-specific lifecycle events.
/// - `loadingWidget`: Widget shown while `onEnter` is executing. Only applies with [builder].
/// - `waitForBinding`: Whether to block the build on `onEnter`. Only applies with [builder].
/// - `initTransitionDuration`: Duration for crossfade animation. Only applies with [builder].
/// - `redirect`: An optional callback for custom redirection logic.
/// - `onExit`: An optional callback for handling logic when the route is exited.
/// - `routes`: A list of nested subroutes. Defaults to an empty list.
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
  /// Defaults to [PlayxPageTransition.cupertino].
  final PlayxPageTransition transition;

  /// Configures various settings for the page.
  ///
  /// The [pageConfiguration] parameter allows you to set page-specific configurations
  /// such as title, key, and other properties, or add custom transitions.
  /// Defaults to [PlayxPageConfiguration()].
  final PlayxPageConfiguration pageConfiguration;

  /// An optional widget displayed while the [binding]'s `onEnter` is being initialized.
  /// Only applies when using [builder], not [initBuilder].
  ///
  /// Overrides the global [PlayxPageConfig.loadingWidget].
  /// Defaults to [SizedBox.shrink()] when neither route-level nor global is set.
  final Widget? loadingWidget;

  /// Optional shell builder for persistent page chrome (AppBar, Drawer, Scaffold).
  /// Only applies when using [builder], not [initBuilder].
  ///
  /// When provided, the shell is rendered **immediately** during navigation
  /// transitions. The `child` parameter contains either the page content
  /// (when initialized) or a loading widget (while `onEnter` is running).
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
  /// Only applies when using [builder], not [initBuilder].
  ///
  /// - `null` (default): Use the global default from [PlayxPageConfig.waitForBinding].
  /// - `true`: Block the build — show loading widget or shell until `onEnter` completes.
  /// - `false`: Render content immediately — `onEnter` runs in the background.
  final bool? waitForBinding;

  /// Duration for the crossfade animation between loading and content.
  /// Only applies when using [builder], not [initBuilder].
  ///
  /// - `null` (default): Use the global default from [PlayxPageConfig.initTransitionDuration].
  /// - [Duration.zero]: No animation (instant swap).
  /// - Any positive duration: Crossfade with that duration.
  final Duration? initTransitionDuration;

  PlayxRoute({
    required super.path,
    super.name,
    GoRouterWidgetBuilder? builder,
    PlayxRouteWidgetBuilder? initBuilder,
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
  })  : assert(
          builder != null || initBuilder != null,
          'Either builder or initBuilder must be provided.',
        ),
        assert(
          builder == null || initBuilder == null,
          'Cannot provide both builder and initBuilder. '
          'Use builder for library-managed loading, or initBuilder for full control.',
        ),
        super(
          pageBuilder: (ctx, state) {
            final Widget pageChild;

            if (binding == null) {
              // No binding — always initialized.
              pageChild = initBuilder != null
                  ? initBuilder(ctx, state, true)
                  : builder!(ctx, state);
            } else {
              pageChild = PlayxPage(
                binding: binding,
                state: state,
                childBuilder: builder,
                initBuilder: initBuilder,
                shellBuilder: shellBuilder,
                loadingWidget: loadingWidget,
                waitForBinding: waitForBinding,
                initTransitionDuration: initTransitionDuration,
              );
            }

            return transition.buildPage(
              config: pageConfiguration,
              child: pageChild,
              state: state,
            );
          },
        );
}
