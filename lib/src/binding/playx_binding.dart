import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

/// An abstract class for defining bindings associated with routes in the PlayxNavigation system.
///
/// The `PlayxBinding` class provides a mechanism to execute specific actions at different
/// stages of a route's lifecycle, such as when the app is initialized, when a route is entered,
/// re-entered, hidden, or exited.
///
/// ### Use Cases:
/// - Initialize and register app-level instances (repositories, datasources, services) during app startup.
/// - Perform initialization or setup when a route is entered.
/// - Release resources or perform cleanup when a route is exited.
/// - Handle special cases when a route is temporarily hidden or revisited.
///
/// To use this, extend `PlayxBinding` and implement its methods.
///
/// ### Example:
/// ```dart
/// class MyRouteBinding extends PlayxBinding {
///   @override
///   Future<void> onInitApp() async {
///     // Register app-level dependencies like repositories and datasources.
///   }
///
///   @override
///   Future<void> onEnter(BuildContext context, GoRouterState state) async {
///     // Initialize resources or fetch data for the route.
///   }
///
///   @override
///   Future<void> onExit(BuildContext context) async {
///     // Cleanup resources or save state when the route is exited.
///   }
/// }
/// ```
///
/// The associated route's lifecycle events ([onInitApp], [onEnter], [onReEnter], [onHidden], [onExit])
/// are triggered automatically by the PlayxNavigation system.
abstract class PlayxBinding {
  /// Called once during the application initialization phase.
  ///
  /// Use this method to initialize and register app-level instances of components,
  /// such as repositories, datasources, services, or any other dependencies that
  /// need to be available throughout the application's lifetime.
  ///
  /// This method is called automatically by the PlayxNavigation system during
  /// initialization (e.g., when [PlayxNavigationBuilder] is first built or when
  /// [PlayxNavigation.boot] is called), before any route lifecycle events are triggered.
  ///
  /// Unlike [onEnter], which is called each time a specific route is navigated to,
  /// [onInitApp] is invoked only once at app startup, making it ideal for
  /// one-time setup tasks.
  ///
  /// ### Example:
  /// ```dart
  /// @override
  /// Future<void> onInitApp() async {
  ///   // Register datasources
  ///   Get.lazyPut<IMyDatasource>(() => MyDatasource());
  ///   // Register repositories
  ///   Get.lazyPut<IMyRepository>(() => MyRepository(Get.find()));
  /// }
  /// ```
  Future<void> onInitApp() async {}

  /// Validates navigation to this binding's route before the page is built.
  ///
  /// Return a location to redirect there instead, or `null` to continue.
  /// Runs after the route's `guards` and before its `redirect`, and only when
  /// this binding's route is the destination (not for its sub-routes).
  ///
  /// Prefer this over navigating away from [onEnter]: the page is never built
  /// with missing data, and `onEnter` / `onExit` don't run.
  ///
  /// ```dart
  /// @override
  /// FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
  ///   final id = int.tryParse(state.pathParameters['id'] ?? '');
  ///   return id == null ? '/jobs' : null;
  /// }
  /// ```
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) => null;

  /// Called when the route is entered for the first time.
  ///
  /// Use this method for initializing resources, fetching data, or setting up the UI
  /// when the associated route is navigated to for the first time.
  ///
  /// - [context]: The [BuildContext] of the route.
  /// - [state]: The [GoRouterState] containing metadata about the current route.
  ///
  /// This method **must** be implemented by subclasses.
  Future<void> onEnter(BuildContext context, GoRouterState state);

  /// Called when the route is re-entered after being visited previously.
  ///
  /// This method is called when the route is revisited after being hidden or popped.
  /// Use this method to handle special cases when the route is re-entered.
  ///
  /// This method is called after [onHidden] is called when the route is hidden
  /// and before [onExit] is called when the route is removed from the stack.
  ///
  /// For example:
  /// - Switching between branches in a [StatefulShellBranch] while the route remains in memory, In this case, [wasPoppedAndReentered] is `false`.
  /// - Navigating back to the route after leaving it temporarily using [PlayxNavigation.toNamed],
  /// without it being removed from the stack.In this case, [onHidden] is called before [onReEnter] and [wasPoppedAndReentered] is `true`.
  ///
  /// - [context]: The [BuildContext] of the route.
  /// - [state]: The [GoRouterState] containing metadata about the current route.
  /// - [wasPoppedAndReentered]: Indicates whether the route was explicitly popped and then revisited.
  Future<void> onReEnter(
    BuildContext context,
    GoRouterState? state,
    bool wasPoppedAndReentered,
  ) async {}

  /// Called when the route is exited and completely removed from the stack.
  ///
  /// Use this method to perform cleanup tasks, such as releasing resources or saving
  /// the state when the route is exited permanently.
  ///
  /// **Behavior with Sub-Routes:** This method is not triggered when navigating between
  /// sub-routes of the same parent route using [PlayxNavigation.goToBranch] method.
  /// Instead, [onHidden] is called when the route is hidden.
  ///
  /// - [context]: The [BuildContext] of the route.
  ///
  /// This method **must** be implemented by subclasses.
  Future<void> onExit(BuildContext context);

  /// Called when the route is hidden but not removed from the stack.
  ///
  /// Use this method to pause tasks, release temporary resources, or handle actions
  /// when the route is no longer visible but remains in the stack.
  ///
  /// Examples:
  /// - Switching to another branch in a [StatefulShellBranch] where the current page
  ///   remains in memory.
  /// - Navigating to a different route using [PlayxNavigation.toNamed] while leaving this route active in the background.
  ///
  /// If the route is removed from the stack, [onExit] is called after [onHidden].
  /// If the user navigates back to the route, [onReEnter] is called.
  ///
  /// - [context]: The [BuildContext] of the route.
  Future<void> onHidden(BuildContext context) async {}

  /// Represents the current state of the page within its lifecycle.
  ///
  /// - [PlayxPageState.enter]: When the route is first entered.
  /// - [PlayxPageState.reEnter]: When the route is re-entered after being visited previously.
  /// - [PlayxPageState.hidden]: When the route is temporarily hidden.
  /// - [PlayxPageState.exit]: When the route is exited and removed from the stack.
  ///
  /// This field is shared by every page using this binding. When the same
  /// binding can back several pages at once, use [PlayxScope.pageState] for a
  /// specific page instead.
  PlayxPageState? currentState;

  /// The scopes of every page currently using this binding (entered, hidden,
  /// or still entering), oldest first.
  ///
  /// A page leaves this list as soon as its visit ends, before [onExit] runs.
  /// So inside [onExit], an empty list means no other page uses this binding,
  /// which is useful when the binding manages shared (unscoped) resources:
  ///
  /// ```dart
  /// @override
  /// Future<void> onExit(BuildContext context) async {
  ///   if (activeScopes.isEmpty) Get.delete<JobsController>();
  /// }
  /// ```
  List<PlayxScope> get activeScopes => PlayxScope.activeScopesOf(this);
}
