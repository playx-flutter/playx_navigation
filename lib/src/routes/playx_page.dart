import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation/src/binding/playx_page_state.dart';
import 'package:playx_navigation/src/models/playx_page_config.dart';

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
/// **Two builder paths:**
///
/// 1. **Standard builder** (`childBuilder`): The library automatically manages
///    loading state — showing the loading widget / shell while `onEnter` runs
///    and revealing the content once initialized.
///
/// 2. **Init-aware builder** (`initBuilder`): The user receives `isInitialized`
///    and takes full control of what to render during and after initialization.
///    Shell builder, loading widget, and transition animation are NOT applied.
///
/// **Shell builder support (standard builder only):**
/// When a [shellBuilder] is provided (either per-route or globally via
/// [PlayxPageConfig]), the shell (AppBar, Drawer, Scaffold) is rendered
/// immediately during the page transition. Only the body content waits
/// for initialization, preventing blank frames during navigation.
///
/// **Lifecycle:**
/// - Mount as top route → `onEnter` fires immediately.
/// - Mount as backstack → deferred, shows loading/shell, fires `onEnter`
///   when the page becomes visible (e.g., user pops back to it).
/// - Dispose → `onExit` fires only if `onEnter` was previously called.
class PlayxPage extends StatefulWidget {
  final PlayxBinding binding;
  final GoRouterState state;

  /// Standard builder — library manages loading/content switching automatically.
  /// Receives only `(context, state)`.
  final GoRouterWidgetBuilder? childBuilder;

  /// Init-aware builder — user gets `isInitialized` and handles everything.
  /// Receives `(context, state, isInitialized)`.
  /// When provided, [shellBuilder], [loadingWidget], [waitForBinding], and
  /// [initTransitionDuration] are not applied (user has full control).
  final PlayxRouteWidgetBuilder? initBuilder;

  /// Optional shell builder for persistent chrome (AppBar, Drawer, Scaffold).
  /// When provided, the shell is rendered immediately — only the body content
  /// depends on initialization state.
  /// Overrides the global [PlayxPageConfig.shellBuilder].
  /// Only applies when using [childBuilder], not [initBuilder].
  final PlayxShellWidgetBuilder? shellBuilder;

  /// An optional widget that is displayed while the [binding]'s `onEnter` is
  /// being initialized. Overrides the global [PlayxPageConfig.loadingWidget].
  /// Defaults to [SizedBox.shrink()] when neither route-level nor global is set.
  /// Only applies when using [childBuilder], not [initBuilder].
  final Widget? loadingWidget;

  /// Whether to block the page build until `onEnter` completes.
  /// Only applies when using [childBuilder], not [initBuilder].
  ///
  /// - `null`: Use the global default from [PlayxPageConfig.waitForBinding].
  /// - `true`: Block the build — show loading/shell until `onEnter` completes.
  /// - `false`: Render immediately — content is shown before `onEnter` completes.
  final bool? waitForBinding;

  /// Duration for the crossfade animation between loading and content.
  /// Only applies when using [childBuilder], not [initBuilder].
  ///
  /// When set, an [AnimatedSwitcher] smoothly transitions from the loading
  /// widget to the page content after `onEnter` completes.
  ///
  /// - `null`: Use the global default from [PlayxPageConfig.initTransitionDuration].
  /// - [Duration.zero]: No animation.
  /// - Any positive duration: Crossfade animation with that duration.
  final Duration? initTransitionDuration;

  const PlayxPage({
    super.key,
    required this.binding,
    required this.state,
    this.childBuilder,
    this.initBuilder,
    this.shellBuilder,
    this.loadingWidget,
    this.waitForBinding,
    this.initTransitionDuration,
  }) : assert(
          childBuilder != null || initBuilder != null,
          'Either childBuilder or initBuilder must be provided.',
        );

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

  /// Wraps [child] in an [AnimatedSwitcher] if a transition duration is set.
  ///
  /// Uses [ValueKey] based on [_initialized] to trigger the crossfade
  /// when the initialization state changes.
  Widget _withTransition(Widget child, Duration? duration) {
    if (duration == null || duration == Duration.zero) {
      return child;
    }
    return AnimatedSwitcher(
      duration: duration,
      child: KeyedSubtree(
        key: ValueKey<bool>(_initialized),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Init-aware builder: user has full control ---
    if (widget.initBuilder != null) {
      return widget.initBuilder!(context, widget.state, _initialized);
    }

    // --- Standard builder: library manages loading state ---
    final globalConfig = PlayxPageConfigProvider.of(context);

    final effectiveShell = widget.shellBuilder ?? globalConfig?.shellBuilder;
    final effectiveLoading = widget.loadingWidget ??
        globalConfig?.loadingWidget ??
        const SizedBox.shrink();
    final effectiveWait =
        widget.waitForBinding ?? globalConfig?.waitForBinding ?? true;
    final effectiveDuration =
        widget.initTransitionDuration ?? globalConfig?.initTransitionDuration;

    // Shell builder present: shell always renders, child depends on init.
    if (effectiveShell != null) {
      final child = _initialized
          ? widget.childBuilder!(context, widget.state)
          : effectiveLoading;
      return effectiveShell(
        context,
        widget.state,
        _initialized,
        _withTransition(child, effectiveDuration),
      );
    }

    // No shell: respect waitForBinding.
    if (!_initialized && effectiveWait) {
      // Blocking mode (default): show loading until ready.
      return _withTransition(effectiveLoading, effectiveDuration);
    }

    // Either initialized, or non-blocking mode: render the child.
    return _withTransition(
      widget.childBuilder!(context, widget.state),
      effectiveDuration,
    );
  }
}
