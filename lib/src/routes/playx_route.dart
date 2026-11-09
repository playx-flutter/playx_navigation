import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:playx_navigation/src/routes/playx_page.dart';

import '../binding/playx_binding.dart';
import '../breadcrumbs/playx_breadcrumb.dart';
import '../controller/playx_route_controller.dart';
import '../guards/playx_guard.dart';
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
/// - `guards`: Optional [PlayxGuard]s evaluated before the route is entered.
/// - `errorBuilder`: Widget shown when the binding's `onEnter` fails or times out.
/// - `enterTimeout`: Maximum time to wait for the binding's `onEnter`.
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
/// Computes the parent location of a page for `PlayxNavigation.back()`.
/// Return `null` to use the automatic parent.
typedef PlayxParentLocation = String? Function(GoRouterState state);

class PlayxRoute<T extends Object> extends GoRoute {
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

  /// Guards evaluated, in order, before this route (and its sub-routes) is
  /// entered. The first guard returning a non-null location redirects there.
  /// Guards run before [redirect].
  final List<PlayxGuard> guards;

  /// Where `PlayxNavigation.back()` goes when there is nothing to pop, e.g.
  /// on web after a refresh, a typed URL or a deep link to this page.
  ///
  /// Return `null` to fall back to the automatic parent: the nearest shorter
  /// path that matches a route (`/jobs/5` → `/jobs`). Set this when the
  /// parent can't be derived from the path, e.g. a top-level `/job/:id` whose
  /// parent is `/jobs`:
  ///
  /// ```dart
  /// parentLocation: (state) => Paths.jobs,
  /// ```
  final PlayxParentLocation? parentLocation;

  /// The label of this route in breadcrumbs (`PlayxBreadcrumbs`,
  /// `PlayxNavigation.breadcrumbs`). Return `null` to leave it out.
  ///
  /// ```dart
  /// breadcrumb: (context, state) => 'Job #${state.pathParameters['id']}',
  /// ```
  ///
  /// Takes precedence over the binding's `PlayxBinding.breadcrumb`; a page can
  /// override it at runtime with `PlayxBreadcrumbLabel`.
  final PlayxBreadcrumbLabelBuilder? breadcrumb;

  /// Builder for the widget shown when the [binding]'s `onEnter` throws or
  /// exceeds [enterTimeout]. Receives a `retry` callback.
  ///
  /// Overrides the global [PlayxPageConfig.errorBuilder].
  final PlayxErrorWidgetBuilder? errorBuilder;

  /// Maximum time to wait for the [binding]'s `onEnter`. On timeout it is
  /// handled like any other `onEnter` error.
  ///
  /// Overrides the global [PlayxPageConfig.enterTimeout]. `null` means no timeout.
  final Duration? enterTimeout;

  /// Creates a route.
  ///
  /// Pass [controller] (and optionally [disposeController]) to give every page
  /// of this route its own controller of type [T]: created when the page is
  /// entered, stored in the page's [PlayxScope], and disposed when it exits.
  /// Read it with `PlayxView<T>` or `context.controller<T>()`. A binding is
  /// optional when a controller is set.
  PlayxRoute({
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
    PlayxParentLocation? parentLocation,
    PlayxBreadcrumbLabelBuilder? breadcrumb,
    PlayxErrorWidgetBuilder? errorBuilder,
    Duration? enterTimeout,
    GoRouterRedirect? redirect,
    ExitCallback? onExit,
    List<RouteBase> routes = const <RouteBase>[],
  }) : this._(
          path: path,
          name: name,
          builder: builder,
          initBuilder: initBuilder,
          transition: transition,
          pageConfiguration: pageConfiguration,
          parentNavigatorKey: parentNavigatorKey,
          binding: binding,
          routeController: controller == null
              ? null
              : PlayxRouteController<T>(controller, disposeController),
          loadingWidget: loadingWidget,
          shellBuilder: shellBuilder,
          waitForBinding: waitForBinding,
          initTransitionDuration: initTransitionDuration,
          guards: guards,
          parentLocation: parentLocation,
          breadcrumb: breadcrumb,
          errorBuilder: errorBuilder,
          enterTimeout: enterTimeout,
          redirect: redirect,
          onExit: onExit,
          routes: routes,
        );

  PlayxRoute._({
    required super.path,
    super.name,
    GoRouterWidgetBuilder? builder,
    PlayxRouteWidgetBuilder? initBuilder,
    required this.transition,
    required this.pageConfiguration,
    super.parentNavigatorKey,
    this.binding,
    PlayxRouteController<T>? routeController,
    this.loadingWidget,
    this.shellBuilder,
    this.waitForBinding,
    this.initTransitionDuration,
    required this.guards,
    this.parentLocation,
    this.breadcrumb,
    this.errorBuilder,
    this.enterTimeout,
    GoRouterRedirect? redirect,
    super.onExit,
    super.routes,
  })  : hasController = routeController != null,
        assert(
          builder != null || initBuilder != null,
          'Either builder or initBuilder must be provided.',
        ),
        assert(
          builder == null || initBuilder == null,
          'Cannot provide both builder and initBuilder. '
          'Use builder for library-managed loading, or initBuilder for full control.',
        ),
        super(
          redirect: composeGuards(
            [...guards, if (binding != null) PlayxBindingGuard(binding)],
            redirect,
          ),
          pageBuilder: (ctx, state) {
            final Widget pageChild;
            final pageBinding = binding ?? routeController?.fallbackBinding;

            if (pageBinding == null) {
              // No binding or controller — always initialized.
              pageChild = initBuilder != null
                  ? initBuilder(ctx, state, true)
                  : builder!(ctx, state);
            } else {
              pageChild = PlayxPage(
                binding: pageBinding,
                state: state,
                childBuilder: builder,
                initBuilder: initBuilder,
                shellBuilder: shellBuilder,
                loadingWidget: loadingWidget,
                waitForBinding: waitForBinding,
                initTransitionDuration: initTransitionDuration,
                errorBuilder: errorBuilder,
                enterTimeout: enterTimeout,
                controller: routeController,
              );
            }

            return transition.buildPage(
              config: pageConfiguration,
              child: pageChild,
              state: state,
            );
          },
        );

  /// Whether this route creates a controller of type [T] for its pages.
  final bool hasController;
}
