import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation/src/binding/playx_page_state.dart';

/// An abstract class for defining bindings associated with routes in the PlayxNavigation system.
///
/// The `PlayxBinding` class provides a mechanism to execute specific actions at different
/// stages of a route's lifecycle, such as when a route is entered, re-entered, hidden, or exited.
///
/// ### Use Cases:
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
/// The associated route's lifecycle events ([onEnter], [onReEnter], [onHidden], [onExit])
/// are triggered automatically by the PlayxNavigation system.
abstract class PlayxBinding {
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

  /// Determines whether [onExit] should be executed when the route is exited.
  ///
  /// **Important:** This field is managed internally by the PlayxNavigation system
  /// and should not be modified directly by subclasses.
  bool shouldExecuteOnExit = false;

  /// Represents the current state of the page within its lifecycle.
  ///
  /// - [PlayxPageState.enter]: When the route is first entered.
  /// - [PlayxPageState.reEnter]: When the route is re-entered after being visited previously.
  /// - [PlayxPageState.hidden]: When the route is temporarily hidden.
  /// - [PlayxPageState.exit]: When the route is exited and removed from the stack.
  PlayxPageState? currentState;
}
