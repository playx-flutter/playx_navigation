import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation/src/binding/playx_page_state.dart';

/// An internal widget that wraps a route's content and manages the
/// [PlayxBinding] lifecycle via standard widget lifecycle methods.
///
/// **Visibility-aware initialization:**
/// `onEnter` only fires when this page is the actual top/visible route.
/// If the page is mounted as a backstack item (e.g., a parent route when
/// deep-linking to a child), `onEnter` is deferred until the page becomes
/// the visible route. This prevents unnecessary controller registration
/// and API calls for pages the user hasn't navigated to yet.
///
/// **Lifecycle:**
/// - Mount as top route → `onEnter` fires immediately, blocking build.
/// - Mount as backstack → deferred, shows empty widget, fires `onEnter`
///   when the page becomes visible (e.g., user pops back to it).
/// - Dispose → `onExit` fires only if `onEnter` was previously called.
class PlayxPage extends StatefulWidget {
  final PlayxBinding binding;
  final GoRouterState state;
  final Widget child;

  /// An optional widget that is displayed while the [binding]'s `onEnter` is being initialized.
  /// Defaults to [SizedBox.shrink()].
  final Widget? loadingWidget;

  const PlayxPage({
    super.key,
    required this.binding,
    required this.state,
    required this.child,
    this.loadingWidget,
  });

  @override
  State<PlayxPage> createState() => _PlayxPageState();
}

class _PlayxPageState extends State<PlayxPage> {
  bool _initialized = false;
  bool _listenerAdded = false;

  @override
  void initState() {
    super.initState();
    _checkAndInitialize();
  }

  /// Checks whether this page is the current top route.
  ///
  /// If it is, `onEnter` is called immediately (blocking the build).
  /// If not, the page is in the backstack — we mark it as [PlayxPageState.pending]
  /// and listen for route changes to fire `onEnter` when it becomes visible.
  Future<void> _checkAndInitialize() async {
    if (_isCurrentlyTopRoute()) {
      await _performOnEnter();
    } else {
      // Deferred — this page is mounted as a backstack item.
      widget.binding.currentState = PlayxPageState.pending;
      _listenerAdded = true;
      PlayxNavigation.addRouteChangeListener(_onRouteChanged);
    }
  }

  /// Listens for route changes to detect when this deferred page becomes visible.
  void _onRouteChanged() {
    if (_initialized) return;
    if (_isCurrentlyTopRoute()) {
      _removeListener();
      _performOnEnter();
    }
  }

  /// Determines if this page's matched location is the current top location.
  bool _isCurrentlyTopRoute() {
    final currentLocation = PlayxNavigation.currentState?.matchedLocation;
    return currentLocation == widget.state.matchedLocation;
  }

  /// Fires `onEnter` on the binding and marks the page as initialized.
  Future<void> _performOnEnter() async {
    widget.binding.currentState = PlayxPageState.enter;
    await widget.binding.onEnter(context, widget.state);
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  void _removeListener() {
    if (_listenerAdded) {
      PlayxNavigation.removeRouteChangeListener(_onRouteChanged);
      _listenerAdded = false;
    }
  }

  @override
  void dispose() {
    _removeListener();
    // Only fire onExit if onEnter was actually called.
    if (_initialized) {
      widget.binding.onExit(context);
      widget.binding.currentState = PlayxPageState.exit;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return widget.loadingWidget ?? const SizedBox.shrink();
    }
    return widget.child;
  }
}
