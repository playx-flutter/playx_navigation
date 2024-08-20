import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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

  /// Called when the route is entered for the first time.
  ///
  /// This method is invoked when the associated route is navigated to. It provides
  /// a place to perform any setup required when the route is first entered.
  ///
  /// - [context]: The [BuildContext] of the route.
  /// - [state]: The [GoRouterState] containing information about the current route.
  ///
  /// This method must be implemented by any subclass of `PlayxBinding`.
  Future<void> onEnter(BuildContext context, GoRouterState state);

  /// Called when the route is exited and removed from the stack.
  ///
  /// This method is invoked when the associated route is removed from the navigation
  /// stack. It is useful for performing
  /// cleanup tasks or releasing resources when the user navigates away from the route.
  ///
  /// - [context]: The [BuildContext] of the route.
  ///
  /// **Behavior with Subroutes:** The [onExit] method of a route is not triggered for its
  /// subroutes individually. Instead, [onExit] for the main route is only called when
  /// the main route, along with all its subroutes, is completely removed from the
  /// navigation stack. Therefore, if you navigate between the main route and its
  /// subroutes, [onExit] for the main route will only be executed when the main route
  /// itself is exited and not merely when navigating between the main route and its
  /// subroutes.
  ///
  /// This method must be implemented by any subclass of `PlayxBinding`.
  Future<void> onExit(BuildContext context);
}
