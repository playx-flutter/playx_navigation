import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation/src/controller/playx_route_controller.dart';
import 'package:playx_navigation/src/models/playx_page_config.dart';

part '../binding/playx_scope.dart';

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

  /// Builder for the widget shown when `onEnter` throws or times out.
  /// Overrides the global [PlayxPageConfig.errorBuilder].
  final PlayxErrorWidgetBuilder? errorBuilder;

  /// Maximum time to wait for `onEnter`. Overrides the global
  /// [PlayxPageConfig.enterTimeout].
  final Duration? enterTimeout;

  /// The route's controller configuration (`PlayxRoute<T>(controller: ...)`).
  /// When set, the controller is created when the page is entered, stored in
  /// the page's [PlayxScope], and disposed when the page exits.
  final PlayxRouteController<Object>? controller;

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
    this.errorBuilder,
    this.enterTimeout,
    this.controller,
  }) : assert(
          childBuilder != null || initBuilder != null,
          'Either childBuilder or initBuilder must be provided.',
        );

  @override
  State<PlayxPage> createState() => _PlayxPageState();
}

/// Internal lifecycle phase of a single [PlayxPage] visit.
enum _Phase {
  /// `onEnter` has not been started (page mounted behind the top route).
  idle,

  /// `onEnter` was started (possibly still running) and the page is visible.
  active,

  /// The page is still in the stack but covered by another page.
  hidden,

  /// `onEnter` failed or timed out.
  failed,

  /// The visit ended: the page was disposed or switched to another
  /// binding / location.
  ended,
}

/// One "visit" of a binding by a page: from `onEnter` to `onExit`.
///
/// A page normally has a single visit. It gets a new one when go_router reuses
/// the page for another location or binding (`replace`, or `go` to the same
/// route with different path parameters), so the old visit's `onExit`
/// completes before the new visit's `onEnter` starts.
class _Visit {
  _Visit(this.binding, this.state) : scope = PlayxScope._(binding, state);

  final PlayxBinding binding;
  final GoRouterState state;
  final PlayxScope scope;
  _Phase phase = _Phase.idle;

  /// Whether `onEnter` completed successfully. `onHidden`, `onReEnter` and
  /// `onExit` only run for entered visits.
  bool entered = false;

  /// The route controller of this visit, once created.
  Object? controller;

  /// The global config captured when [controller] was created, used again
  /// when it is released (the page may be unmounted by then).
  PlayxPageConfig? controllerConfig;

  /// An error thrown while creating [controller] synchronously; rethrown by
  /// `onEnter` so it goes through the normal error handling.
  Object? createError;
  StackTrace? createStackTrace;

  PlayxPageLifecycle? get lifecycle {
    final c = controller;
    return c is PlayxPageLifecycle ? c : null;
  }

  bool get started => phase == _Phase.active || phase == _Phase.hidden;
}

/// Tracks which visit last wrote [PlayxBinding.currentState], so a page that
/// ends doesn't clobber the state written by another live page sharing the
/// same binding.
final Expando<_Visit> _stateOwner =
    Expando<_Visit>('PlayxBinding.currentState');

/// Pages that need to react to the latest route change.
///
/// Every live page listens to the router, so one navigation notifies all of
/// them. Their transitions are collected here and applied together, with every
/// "leaving" transition (`onHidden`) started before any "entering" one
/// (`onEnter`, `onReEnter`), regardless of the order the pages were mounted.
final Set<_PlayxPageState> _dirtyPages = <_PlayxPageState>{};

void _flushDirtyPages() {
  final pages = _dirtyPages.toList();
  _dirtyPages.clear();
  for (final page in pages) {
    page._applyRouteChange(leaving: true);
  }
  for (final page in pages) {
    page._applyRouteChange(leaving: false);
  }
}

/// The page keys of the router's current page stack, bottom to top.
///
/// Shell matches are flattened into the pages they contain. Pages of inactive
/// [StatefulShellRoute] branches are not part of the stack.
List<Object> _currentPageKeys() {
  final keys = <Object>[];
  void visit(List<RouteMatchBase> matches) {
    for (final match in matches) {
      if (match is ShellRouteMatch) {
        visit(match.matches);
      } else {
        keys.add(match.pageKey);
      }
    }
  }

  visit(PlayxNavigation.goRouter.routerDelegate.currentConfiguration.matches);
  return keys;
}

/// Whether [current] is [previous] with one or more pages removed from the
/// top, i.e. the pages above the new top page were popped.
bool _isPoppedFrom(List<Object> previous, List<Object> current) {
  if (current.isEmpty || current.length >= previous.length) return false;
  for (var i = 0; i < current.length; i++) {
    if (current[i] != previous[i]) return false;
  }
  return true;
}

class _PlayxPageState extends State<PlayxPage> {
  late _Visit _visit;
  Object? _error;
  StackTrace? _stackTrace;

  /// The page stack seen on the latest route change, and the one before the
  /// first change that hasn't been applied yet. Used for
  /// `wasPoppedAndReentered`.
  List<Object> _lastKeys = const [];
  List<Object> _previousKeys = const [];

  /// Lifecycle callbacks of this page run strictly one after another, so e.g.
  /// `onHidden` never overlaps a still-running `onEnter`, and `onExit` always
  /// runs after it.
  Future<void> _tail = Future<void>.value();
  int _pending = 0;

  bool get _initialized => _visit.entered;

  /// The visit whose callback is currently running, if any.
  _Visit? _runningVisit;

  /// The scope [PlayxScope.of] returns for this page's own context: the one
  /// of the running callback (which may belong to a visit that just ended),
  /// otherwise the current visit's.
  PlayxScope get _scopeForCallbacks => (_runningVisit ?? _visit).scope;

  @override
  void initState() {
    super.initState();
    _pageOfElement[context] = this;
    _visit = _Visit(widget.binding, widget.state);
    _lastKeys = _currentPageKeys();
    PlayxNavigation.addRouteChangeListener(_onRouteChanged);
    _evaluate(leaving: false);
  }

  @override
  void didUpdateWidget(PlayxPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameVisit = identical(oldWidget.binding, widget.binding) &&
        oldWidget.state.matchedLocation == widget.state.matchedLocation;
    if (sameVisit) return;
    // go_router reused this page for another location or binding: end the
    // old visit, then start a new one (onExit completes before onEnter).
    _endVisit(_visit);
    _visit = _Visit(widget.binding, widget.state);
    _error = null;
    _stackTrace = null;
    _evaluate(leaving: false);
  }

  /// Whether this page is the visible top page of the router.
  ///
  /// Compared by page key, so two pages of the same route (e.g. pushed
  /// details of different items) are told apart.
  bool _isTop() {
    final current = PlayxNavigation.currentState;
    return current != null && current.pageKey == widget.state.pageKey;
  }

  void _onRouteChanged() {
    if (!mounted) return;
    if (!_dirtyPages.contains(this)) _previousKeys = _lastKeys;
    _lastKeys = _currentPageKeys();
    if (_dirtyPages.isEmpty) scheduleMicrotask(_flushDirtyPages);
    _dirtyPages.add(this);
  }

  void _applyRouteChange({required bool leaving}) {
    if (!mounted) return;
    _evaluate(leaving: leaving);
  }

  void _setBindingState(_Visit visit, PlayxPageState state) {
    visit.scope._pageState = state;
    visit.binding.currentState = state;
    _stateOwner[visit.binding] = visit;
  }

  void _addActiveScope(_Visit visit) {
    (_activeScopes[visit.binding] ??= <PlayxScope>[]).add(visit.scope);
  }

  void _removeActiveScope(_Visit visit) {
    _activeScopes[visit.binding]?.remove(visit.scope);
  }

  /// Decides, synchronously, which lifecycle transition (if any) the latest
  /// route change implies for the current visit, and schedules its callback.
  ///
  /// With [leaving] only transitions that hide the page are applied;
  /// otherwise only the ones that enter or re-enter it (or mark it pending).
  void _evaluate({required bool leaving}) {
    final visit = _visit;
    final top = _isTop();
    switch (visit.phase) {
      case _Phase.idle:
        if (leaving) break;
        if (top) {
          visit.phase = _Phase.active;
          _addActiveScope(visit);
          _setBindingState(visit, PlayxPageState.enter);
          final timeout = widget.enterTimeout ??
              PlayxPageConfigProvider.read(context)?.enterTimeout;
          // Create the controller now, so it exists on the first build. If
          // boot is still running, or a previous visit's exit is still queued
          // (replace / path parameter change), onEnter creates it in the queue
          // instead, so the old controller is disposed first.
          if (PlayxNavigation.isInitialized && _pending == 0) {
            _createController(visit);
          }
          _enqueue(visit, () => _performOnEnter(visit, timeout));
        } else {
          // Mounted behind the top route (e.g. parent of a deep-linked child,
          // or a preloaded shell branch).
          _setBindingState(visit, PlayxPageState.pending);
        }
      case _Phase.active:
        if (leaving && !top) {
          visit.phase = _Phase.hidden;
          _setBindingState(visit, PlayxPageState.hidden);
          final ctx = context;
          _enqueue(visit, () async {
            if (!visit.entered) return;
            await visit.binding.onHidden(ctx);
            await visit.lifecycle?.onPageHidden();
          });
        }
      case _Phase.hidden:
        if (!leaving && top) {
          final wasPopped = _isPoppedFrom(_previousKeys, _lastKeys);
          final routeState = PlayxNavigation.currentState;
          visit.phase = _Phase.active;
          _setBindingState(visit, PlayxPageState.reEnter);
          final ctx = context;
          _enqueue(visit, () async {
            if (!visit.entered) return;
            await visit.binding.onReEnter(ctx, routeState, wasPopped);
            await visit.lifecycle?.onPageReEnter(routeState, wasPopped);
          });
        }
      case _Phase.failed:
      case _Phase.ended:
        break;
    }
  }

  /// Runs [callback] after every previously scheduled callback of this page.
  ///
  /// When nothing is pending the callback starts synchronously. Errors from
  /// callbacks are reported without breaking the chain.
  void _enqueue(_Visit visit, Future<void> Function() callback) {
    Future<void> tracked() {
      _runningVisit = visit;
      return Future<void>.sync(callback)
          .whenComplete(() => _runningVisit = null);
    }

    _pending++;
    final Future<void> run =
        _pending == 1 ? tracked() : _tail.then((_) => tracked());
    _tail = run
        .catchError((Object error, StackTrace stackTrace) => _report(
              error,
              stackTrace,
              'while running a ${visit.binding.runtimeType} lifecycle callback',
            ))
        .whenComplete(() => _pending--);
  }

  void _report(Object error, StackTrace stackTrace, String description) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'playx_navigation',
      context: ErrorDescription(description),
    ));
  }

  /// Runs `onEnter` for [visit] and marks it as entered.
  ///
  /// Waits for [PlayxNavigation.boot] (and therefore every `onInitApp`) first.
  /// If `onEnter` throws or exceeds [timeout], the error is stored (and
  /// reported when no error builder handles it) instead of being left as an
  /// unhandled async error.
  Future<void> _performOnEnter(_Visit visit, Duration? timeout) async {
    try {
      if (!PlayxNavigation.isInitialized) {
        await PlayxNavigation.ensureInitialized;
      }
      // Ended while waiting for boot: onEnter never runs, so neither does
      // onExit.
      if (visit.phase == _Phase.ended) return;
      final createError = visit.createError;
      if (createError != null) {
        Error.throwWithStackTrace(
            createError, visit.createStackTrace ?? StackTrace.empty);
      }
      if (widget.controller != null && visit.controller == null) {
        _createController(visit, rethrowErrors: true);
        // The controller now exists: let non-blocking pages build content.
        if (mounted && visit == _visit) setState(() {});
      }
      var future = Future<void>.sync(() async {
        await visit.binding.onEnter(context, visit.state);
        await visit.lifecycle?.onPageEnter(visit.state);
      });
      if (timeout != null) future = future.timeout(timeout);
      await future;
    } catch (error, stackTrace) {
      final description = 'while running ${visit.binding.runtimeType}.onEnter';
      if (!mounted || visit != _visit) {
        // Nobody is left to show the error.
        _report(error, stackTrace, description);
        return;
      }
      // onEnter did not complete, so the page is not entered.
      visit.phase = _Phase.failed;
      _removeActiveScope(visit);
      _setBindingState(visit, PlayxPageState.pending);
      final hasErrorBuilder = widget.errorBuilder != null ||
          PlayxPageConfigProvider.read(context)?.errorBuilder != null;
      if (!hasErrorBuilder) _report(error, stackTrace, description);
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
      });
      return;
    }
    // Also counts when the visit ended while onEnter was running, so the
    // queued onExit cleans up whatever onEnter set up.
    visit.entered = true;
    if (mounted && visit == _visit) setState(() {});
  }

  /// Creates the route controller of [visit] (if the route has one and it
  /// doesn't exist yet) and stores it in the visit's scope.
  ///
  /// Errors are kept on the visit and rethrown by `onEnter`, unless
  /// [rethrowErrors] is set.
  void _createController(_Visit visit, {bool rethrowErrors = false}) {
    final config = widget.controller;
    if (config == null || visit.controller != null) return;
    try {
      final pageConfig = PlayxPageConfigProvider.read(context);
      visit.controllerConfig = pageConfig;
      visit.controller =
          config.createIn(context, visit.state, visit.scope, pageConfig);
    } catch (error, stackTrace) {
      if (rethrowErrors) rethrow;
      visit.createError = error;
      visit.createStackTrace = stackTrace;
    }
  }

  /// Unregisters and disposes the route controller of [visit], if created.
  void _releaseController(_Visit visit) {
    final controller = visit.controller;
    final config = widget.controller;
    if (controller == null || config == null) return;
    visit.controller = null;
    config.release(controller, visit.scope, visit.controllerConfig);
  }

  /// Runs `onEnter` again after a failure.
  void _retry() {
    if (_error == null || !mounted) return;
    _releaseController(_visit);
    _visit.scope._dispose();
    _visit = _Visit(widget.binding, widget.state);
    setState(() {
      _error = null;
      _stackTrace = null;
    });
    _evaluate(leaving: false);
  }

  /// Ends [visit]: queues `onExit` if `onEnter` was started (it runs after any
  /// still-running callback, so exit never overlaps enter).
  ///
  /// The visit's [PlayxScope] is removed from the binding's active scopes right
  /// away, and disposed after `onExit` completes.
  void _endVisit(_Visit visit) {
    final wasStarted = visit.started;
    visit.phase = _Phase.ended;
    _removeActiveScope(visit);
    visit.scope._pageState = PlayxPageState.exit;
    final ctx = context;
    _enqueue(visit, () async {
      try {
        if (wasStarted && visit.entered) {
          try {
            await visit.binding.onExit(ctx);
          } finally {
            await visit.lifecycle?.onPageExit();
          }
        }
      } finally {
        _releaseController(visit);
        visit.scope._dispose();
      }
    });
    if (_stateOwner[visit.binding] == visit) {
      visit.binding.currentState = PlayxPageState.exit;
    }
  }

  @override
  void dispose() {
    PlayxNavigation.removeRouteChangeListener(_onRouteChanged);
    _dirtyPages.remove(this);
    _endVisit(_visit);
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
    return PlayxScopeProvider(
        scope: _visit.scope, child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    // --- onEnter failed: show the error widget if one is configured ---
    if (_error != null) {
      final errorBuilder = widget.errorBuilder ??
          PlayxPageConfigProvider.of(context)?.errorBuilder;
      if (errorBuilder != null) {
        return errorBuilder(
          context,
          widget.state,
          _error!,
          _stackTrace ?? StackTrace.empty,
          _retry,
        );
      }
    }

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

    // A route controller must exist before the content can build, even in
    // non-blocking mode (e.g. a pending page behind a deep link).
    final controllerMissing =
        widget.controller != null && _visit.controller == null;

    // No shell: respect waitForBinding.
    if (!_initialized && (effectiveWait || controllerMissing)) {
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
