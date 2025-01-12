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
/// between routes. like handling [PlayxBinding] onEnter and onExit methods.
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
  GoRoute? _currentRoute;

  @override
  void initState() {
    super.initState();
    setupRouter();
  }

  /// Initializes the [PlayxNavigation] system and sets up route change listeners.
  void setupRouter() {
    if (widget.router != null) {
      PlayxNavigation.boot(router: widget.router!);
    }
    PlayxNavigation.addRouteChangeListener(listenToRouteChanges);
  }

  /// Callback to listen to route changes and execute binding actions.
  ///
  /// This method is invoked whenever the route changes. It compares the
  /// current route with the previous one, and if the previous route has a
  /// binding with an `onExit` action, that action is executed before
  /// updating the current route.
  void listenToRouteChanges() {
    final currentRoute = PlayxNavigation.currentRoute;

    final previousRoute = _currentRoute;
    final currentBinding =
        currentRoute is PlayxRoute ? currentRoute.binding : null;

    if (previousRoute is PlayxRoute) {
      final binding = previousRoute.binding;

      if (binding == null) {
        _currentRoute = currentRoute;
        return;
      }
      final state = binding.currentState;
      if (state != PlayxPageState.hidden) {
        binding.onHidden(
          context,
        );
        binding.currentState = PlayxPageState.hidden;
      }
    }

    if (currentBinding != null) {
      if (currentBinding.currentState != PlayxPageState.enter &&
          currentBinding.currentState != PlayxPageState.reEnter) {
        currentBinding.onReEnter(context, null, true);
        currentBinding.currentState = PlayxPageState.reEnter;
      }
    }

    _currentRoute = currentRoute;
  }

  @override
  void dispose() {
    PlayxNavigation.removeRouteChangeListener(listenToRouteChanges);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: widget.builder);
  }
}
