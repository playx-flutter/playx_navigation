import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playx_navigation/src/binding/playx_binding.dart';
import 'package:playx_navigation/src/binding/playx_page_state.dart';
import 'package:playx_navigation/src/playx_navigation.dart';

import '../routes/playx_route.dart';

/// A widget that initializes and manages the [PlayxNavigation] system.
///
/// The [PlayxNavigationBuilder] widget is responsible for setting up the
/// [PlayxNavigation] instance and listening to route changes in the
/// navigation system. It ensures that the navigation system is properly
/// initialized and provides a way to execute specific logic when navigating
/// between routes — specifically handling [PlayxBinding.onHidden] and
/// [PlayxBinding.onReEnter] lifecycle events.
///
/// **Lifecycle responsibilities:**
/// - `onHidden`: Fired when the current route is covered by another route
///   (push, branch switch) but remains in the navigation stack.
/// - `onReEnter`: Fired when a previously hidden route returns to the foreground
///   (pop, branch switch back).
/// - `onEnter` / `onExit`: Handled by [PlayxPage] widget lifecycle, not here.
///
/// This widget is typically placed high in the widget tree to wrap the entire
/// application or the part of the app that relies on navigation.
///
/// Example usage:
/// ```dart
/// PlayxNavigationBuilder(
///   router: myRouter,
///   builder: (context) {
///     return MyApp();
///   },
/// )
/// ```
///
/// The [router] parameter is optional. If provided, it will be used to
/// initialize the [PlayxNavigation] system. If not provided, the existing
/// [PlayxNavigation] instance must be initialized elsewhere in the code.
class PlayxNavigationBuilder extends StatefulWidget {
  /// The builder function that creates the child widget for this widget.
  /// Typically, this is where you return your app's main widget.
  final Widget Function(BuildContext context) builder;

  /// An optional [GoRouter] instance to initialize the [PlayxNavigation]
  /// system. If not provided, you must ensure [PlayxNavigation.boot()] is
  /// called elsewhere in your code.
  final GoRouter? router;

  const PlayxNavigationBuilder({super.key, required this.builder, this.router});

  @override
  State<PlayxNavigationBuilder> createState() => _PlayxNavigationBuilderState();
}

class _PlayxNavigationBuilderState extends State<PlayxNavigationBuilder> {
  /// Tracks the previous top route to detect transitions.
  GoRoute? _previousTopRoute;

  /// Tracks the previous matched location for wasPoppedAndReentered detection.
  String? _previousMatchedLocation;

  @override
  void initState() {
    super.initState();
    setupRouter();
  }

  /// Initializes the [PlayxNavigation] system and sets up route change listeners.
  ///
  /// If a [GoRouter] is provided, this method calls [PlayxNavigation.boot]
  /// which initializes the navigation system and invokes [PlayxBinding.onInitApp]
  /// on all discovered bindings before adding the route change listener.
  Future<void> setupRouter() async {
    if (widget.router != null) {
      await PlayxNavigation.boot(router: widget.router!);
    }
    PlayxNavigation.addRouteChangeListener(_onRouteChanged);
  }

  /// Callback invoked whenever the route changes.
  ///
  /// Detects transitions between routes and fires the appropriate binding
  /// lifecycle methods:
  /// - [PlayxBinding.onHidden] on the previous binding when it's covered.
  /// - [PlayxBinding.onReEnter] on the current binding when it was previously hidden.
  ///
  /// Determines [wasPoppedAndReentered] by checking path relationships:
  /// - If the previous location was a sub-path of the current location,
  ///   a child route was popped → `true`.
  /// - Otherwise (branch switch, go navigation) → `false`.
  void _onRouteChanged() {
    final currentTopRoute = PlayxNavigation.currentRoute;
    final currentState = PlayxNavigation.currentState;
    final currentMatchedLocation = currentState?.matchedLocation;

    final previousTopRoute = _previousTopRoute;

    // Get bindings for previous and current top routes.
    final previousBinding =
        previousTopRoute is PlayxRoute ? previousTopRoute.binding : null;
    final currentBinding =
        currentTopRoute is PlayxRoute ? currentTopRoute.binding : null;

    // If routes haven't changed, nothing to do.
    if (previousTopRoute == currentTopRoute) {
      _previousTopRoute = currentTopRoute;
      _previousMatchedLocation = currentMatchedLocation;
      return;
    }

    // --- Handle the LEAVING route (previous) ---
    if (previousBinding != null && previousBinding != currentBinding) {
      final state = previousBinding.currentState;
      // Only fire onHidden if the binding is currently active (enter or reEnter).
      // Don't fire if already hidden or exited.
      if (state == PlayxPageState.enter || state == PlayxPageState.reEnter) {
        previousBinding.onHidden(context);
        previousBinding.currentState = PlayxPageState.hidden;
      }
    }

    // --- Handle the ENTERING route (current) ---
    if (currentBinding != null && currentBinding != previousBinding) {
      final state = currentBinding.currentState;
      // If the binding was previously hidden, it's being re-entered.
      if (state == PlayxPageState.hidden) {
        // Determine wasPoppedAndReentered:
        // If the previous matched location is a sub-path of the current one,
        // it means a child route was popped, revealing this parent route.
        final wasPoppedAndReentered = _wasChildPopped(
          previousLocation: _previousMatchedLocation,
          currentLocation: currentMatchedLocation,
        );

        currentBinding.onReEnter(
          context,
          currentState,
          wasPoppedAndReentered,
        );
        currentBinding.currentState = PlayxPageState.reEnter;
      }
      // If the binding state is enter or null, PlayxPage.initState handles onEnter.
      // We don't fire onReEnter or onEnter here in that case.
    }

    _previousTopRoute = currentTopRoute;
    _previousMatchedLocation = currentMatchedLocation;
  }

  /// Determines if a child route was popped (backward navigation).
  ///
  /// Returns `true` if the [previousLocation] is a sub-path of [currentLocation],
  /// meaning a child route was on top and was popped to reveal the current parent.
  ///
  /// Returns `false` for branch switches or unrelated navigation where neither
  /// location is a prefix of the other.
  bool _wasChildPopped({
    required String? previousLocation,
    required String? currentLocation,
  }) {
    if (previousLocation == null || currentLocation == null) return false;
    if (previousLocation == currentLocation) return false;

    // If the previous location starts with the current location,
    // it means we navigated from a child (deeper path) back to a parent.
    // e.g., /products/123 → /products
    return previousLocation.startsWith(currentLocation);
  }

  @override
  void dispose() {
    PlayxNavigation.removeRouteChangeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: widget.builder);
  }
}
