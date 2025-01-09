import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

/// An abstract class representing a binding for a route in the PlayxNavigation system.
///
/// The `PlayxBinding` class provides a way to define actions that should be executed
/// when a route is entered or exited. This is useful for performing setup or cleanup
/// tasks when navigating between different parts of an application.
///
/// You can create custom bindings by extending this class and implementing the
/// [onEnter] and [onExit] methods. These methods will be automatically called by
/// the PlayxNavigation system at the appropriate times.
///
/// Example:
/// ```dart
/// class MyRouteBinding extends PlayxBinding {
///   @override
///   Future<void> onEnter(BuildContext context, GoRouterState state) async {
///     // Perform setup when the route is entered.
///   }
///
///   @override
///   Future<void> onExit(BuildContext context) async {
///     // Perform cleanup when the route is exited.
///   }
/// }
/// ```
///
/// This binding can be associated with a route, and the PlayxNavigation system will
/// call [onEnter] when the route is first entered and [onExit] when the route is removed
/// from the navigation stack.
abstract class PlayxBinding {
  /// Determines whether the [onExit] method should be executed when the route is exited.
  ///
  /// **Note:** This field is handled by the navigation system to manage route exit
  /// scenarios and should not be overridden. The navigation system will set this field
  /// as needed to determine if [onExit] should be called.
  bool shouldExecuteOnExit = false;

  /// Determines whether the [onHidden] method should be executed when the route is hidden.
  ///
  /// **Note:** This field is handled by the navigation system to manage route hidden
  /// scenarios and should not be overridden. The navigation system will set this field
  /// as needed to determine if [onHidden] should be called.
  bool isHidden = false;

  /// Called when the route is entered for the first time only.
  ///
  /// This method is invoked when the associated route is navigated to. It provides
  /// a place to perform any setup required when the route is first entered.
  ///
  /// - [context]: The [BuildContext] of the route.
  /// - [state]: The [GoRouterState] containing information about the current route.
  ///
  /// This method must be implemented by any subclass of `PlayxBinding`.
  Future<void> onEnter(BuildContext context, GoRouterState? state);

  /// Called when the route is re-entered again before calling [onExit].
  ///
  /// This method is invoked when the associated route is navigated to again after
  /// being removed from the navigation stack. It provides a place to perform any setup
  /// required when the route is re-entered.
  ///
  ///
  /// For Example navigating to another branch of [StatefulShellBranch] will keep the current page and allows to
  /// navigate to other pages and navigate back to this page without calling [onExit].
  ///
  /// Navigating through [PlayxNavigation.toNamed] will not call [onReEnter] as it will be considered still visible on navigation stack.
  /// As when pressing back button will not call [onReEnter].
  ///
  /// - [context]: The [BuildContext] of the route.
  /// - [state]: The [GoRouterState] containing information about the current route.
  Future<void> onReEnter(BuildContext context, GoRouterState? state) async {}

  /// Called when the route is exited and removed from the stack.
  ///
  /// This method is invoked when the associated route is removed from the navigation
  /// stack. It is useful for performing
  /// cleanup tasks or releasing resources when the user navigates away from the route.
  ///
  /// - [context]: The [BuildContext] of the route.
  ///
  /// **Behavior with Sub Routes:** The [onExit] method of a route is not triggered for its
  /// Sub Routes individually. Instead, [onExit] for the main route is only called when
  /// the main route, along with all its Sub Routes, is completely removed from the
  /// navigation stack. Therefore, if you navigate between the main route and its
  /// Sub Routes, [onExit] for the main route will only be executed when the main route
  /// itself is exited and not merely when navigating between the main route and its Sub Routes.
  ///
  /// This method must be implemented by any subclass of `PlayxBinding`.
  Future<void> onExit(BuildContext context);

  /// Called when the route is hidden and not removed from the stack.
  ///
  /// This method is invoked when the associated route is hidden from the navigation stack.
  /// It is useful for performing cleanup tasks or releasing resources when the user navigates away from the route.
  ///
  /// For Example navigating to another branch of [StatefulShellBranch] will keep the current page and allows to
  /// navigate to other pages and navigate back to this page without calling [onExit].
  ///
  /// If the route is removed from the navigation stack, [onExit] will be called instead after [onHidden].
  /// If the user navigates back to the route, [onReEnter] will be called instead of [onHidden].
  ///
  /// If the route is hidden and navigated to another route by for example [PlayxNavigation.toNamed] which keep the route in navigation stack,
  /// The [onHidden] will not be called.
  Future<void> onHidden(BuildContext context) async {}
}
