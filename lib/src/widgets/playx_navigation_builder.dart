import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playx_navigation/src/binding/playx_binding.dart';
import 'package:playx_navigation/src/models/playx_page_config.dart';
import 'package:playx_navigation/src/playx_navigation.dart';

/// A widget that initializes and manages the [PlayxNavigation] system.
///
/// The [PlayxNavigationBuilder] widget is responsible for booting the
/// [PlayxNavigation] instance (running every [PlayxBinding.onInitApp]) and for
/// providing the global [PlayxPageConfig] to routes.
///
/// **Global configuration:**
/// Use the [config] parameter to set default behavior for all routes,
/// including a global loading widget, shell builder, and whether routes
/// should block their build on `onEnter` completion.
///
/// **Lifecycle responsibilities:**
/// Each route's [PlayxBinding] lifecycle (`onEnter`, `onHidden`, `onReEnter`,
/// `onExit`) is managed per page instance by [PlayxPage], which waits for
/// boot to finish before calling `onEnter`.
///
/// This widget is typically placed high in the widget tree to wrap the entire
/// application or the part of the app that relies on navigation.
///
/// Example usage:
/// ```dart
/// PlayxNavigationBuilder(
///   router: myRouter,
///   config: PlayxPageConfig(
///     loadingWidget: Center(child: CircularProgressIndicator()),
///     waitForBinding: false,
///     shellBuilder: (context, state, isInitialized, child) => Scaffold(
///       appBar: AppBar(title: Text('My App')),
///       body: child,
///     ),
///   ),
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

  /// Optional global configuration for all [PlayxPage] instances.
  ///
  /// Sets defaults for [loadingWidget], [waitForBinding], and [shellBuilder]
  /// that individual routes can override.
  ///
  /// When not provided, routes use built-in defaults:
  /// - `loadingWidget`: [SizedBox.shrink()]
  /// - `waitForBinding`: `true` (block build until `onEnter` completes)
  /// - `shellBuilder`: `null` (no shell)
  final PlayxPageConfig? config;

  const PlayxNavigationBuilder({
    super.key,
    required this.builder,
    this.router,
    this.config,
  });

  @override
  State<PlayxNavigationBuilder> createState() => _PlayxNavigationBuilderState();
}

class _PlayxNavigationBuilderState extends State<PlayxNavigationBuilder> {
  @override
  void initState() {
    super.initState();
    setupRouter();
  }

  /// Initializes the [PlayxNavigation] system.
  ///
  /// If a [GoRouter] is provided, this method calls [PlayxNavigation.boot]
  /// which initializes the navigation system and invokes [PlayxBinding.onInitApp]
  /// on all discovered bindings before adding the route change listener.
  Future<void> setupRouter() async {
    if (widget.router != null) {
      try {
        await PlayxNavigation.boot(router: widget.router!);
      } catch (error, stackTrace) {
        // Pages waiting on PlayxNavigation.ensureInitialized receive the same
        // error and surface it through their error handling.
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'playx_navigation',
          context: ErrorDescription('while booting PlayxNavigation'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Builder(builder: widget.builder);

    // Wrap with config provider if a config is specified.
    if (widget.config != null) {
      child = PlayxPageConfigProvider(
        config: widget.config!,
        child: child,
      );
    }

    return child;
  }
}
