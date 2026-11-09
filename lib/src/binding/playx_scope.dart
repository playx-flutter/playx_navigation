part of '../routes/playx_page.dart';

/// The scope of one page visit: from the binding's `onEnter` to its `onExit`.
///
/// Every page with a [PlayxBinding] gets its own scope. Two pages of the same
/// route (for example `details/1` pushed over `details/2`), or two routes
/// sharing one binding instance, each have a different scope.
///
/// Use it to keep controllers (GetX, Bloc, ChangeNotifier, anything) per page
/// instead of per type, so stacked pages never overwrite or delete each
/// other's controllers:
///
/// - [id] is unique per visit. Use it as a GetX `tag`, a Riverpod family key,
///   etc.
/// - [put] / [get] store objects in the scope itself, without any global
///   registry. Pass `dispose` to clean them up automatically.
/// - [onDispose] callbacks run after the binding's `onExit` completes.
///
/// Get the scope with [PlayxScope.of]:
/// - inside binding callbacks, from the `context` they receive;
/// - inside the page's widgets, from any `BuildContext` below the page.
///
/// ```dart
/// class JobDetailsBinding extends PlayxBinding {
///   @override
///   Future<void> onEnter(BuildContext context, GoRouterState state) async {
///     final scope = PlayxScope.of(context);
///     scope.put(
///       JobDetailsController(id: int.parse(state.pathParameters['id']!)),
///       dispose: (controller) => controller.dispose(),
///     );
///   }
///
///   @override
///   Future<void> onExit(BuildContext context) async {}
/// }
///
/// // In the page:
/// final controller = PlayxScope.of(context).get<JobDetailsController>();
/// ```
class PlayxScope {
  PlayxScope._(this.binding, this.state)
      : id = '${state.pageKey.value}#${_nextScopeId++}';

  static int _nextScopeId = 0;

  /// A unique identifier of this page visit.
  ///
  /// Stable for the whole visit and never reused, so it is safe to use as a
  /// GetX `tag` or any other registry key.
  final String id;

  /// The binding this scope belongs to.
  final PlayxBinding binding;

  /// The [GoRouterState] of the page this scope belongs to.
  final GoRouterState state;

  PlayxPageState _pageState = PlayxPageState.pending;
  bool _disposed = false;
  final Map<Type, Object> _values = <Type, Object>{};
  final List<void Function()> _disposers = <void Function()>[];

  /// The lifecycle state of this page visit.
  ///
  /// Unlike [PlayxBinding.currentState], which is shared by every page using
  /// the binding, this belongs to this page only.
  PlayxPageState get pageState => _pageState;

  /// Whether this page is currently the visible top page.
  bool get isActive =>
      _pageState == PlayxPageState.enter ||
      _pageState == PlayxPageState.reEnter;

  /// Whether the visit ended and its disposers ran.
  bool get isDisposed => _disposed;

  /// Stores [value] in this scope under type [T] and returns it.
  ///
  /// [dispose] is called with [value] after the binding's `onExit` completes.
  /// Storing another value under the same [T] replaces the previous value
  /// (the previous value's `dispose` still runs when the scope ends).
  T put<T extends Object>(T value, {void Function(T value)? dispose}) {
    _assertNotDisposed();
    _values[T] = value;
    if (dispose != null) _disposers.add(() => dispose(value));
    return value;
  }

  /// Returns the value stored under type [T].
  ///
  /// Throws a [StateError] if there is none.
  T get<T extends Object>() {
    final value = _values[T];
    if (value == null) {
      throw StateError(
        'No $T found in the PlayxScope of ${binding.runtimeType} ($id). '
        'Put it in the scope first, e.g. in onEnter: '
        'PlayxScope.of(context).put<$T>(...).',
      );
    }
    return value as T;
  }

  /// Returns the value stored under type [T], or `null` if there is none.
  T? maybeGet<T extends Object>() => _values[T] as T?;

  /// Whether a value is stored under type [T].
  bool has<T extends Object>() => _values.containsKey(T);

  /// Registers [callback] to run after the binding's `onExit` completes.
  ///
  /// Callbacks run in reverse registration order. Use it to unregister
  /// objects from other registries, e.g.
  /// `scope.onDispose(() => Get.delete<MyController>(tag: scope.id))`.
  void onDispose(void Function() callback) {
    _assertNotDisposed();
    _disposers.add(callback);
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError(
        'The PlayxScope of ${binding.runtimeType} ($id) is already disposed.',
      );
    }
  }

  void _dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final disposer in _disposers.reversed) {
      try {
        disposer();
      } catch (error, stackTrace) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'playx_navigation',
          context: ErrorDescription(
            'while disposing the PlayxScope of ${binding.runtimeType}',
          ),
        ));
      }
    }
    _disposers.clear();
    _values.clear();
  }

  /// Returns the scope for [context].
  ///
  /// [context] can be the `context` given to a [PlayxBinding] callback, or
  /// any context inside the page's widget tree.
  ///
  /// Throws a [StateError] if [context] is not inside a page with a binding.
  static PlayxScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw StateError(
        'No PlayxScope found for this context. PlayxScope.of must be called '
        'from a PlayxBinding callback or from a widget inside a PlayxRoute '
        'that has a binding.',
      );
    }
    return scope;
  }

  /// Like [of], but returns `null` when no scope is found.
  static PlayxScope? maybeOf(BuildContext context) {
    final page = _pageOfElement[context];
    if (page != null) return page._scopeForCallbacks;
    return context.getInheritedWidgetOfExactType<_PlayxScopeProvider>()?.scope;
  }

  /// The scopes of every page currently using [binding] (entered, hidden, or
  /// still entering), oldest first.
  ///
  /// A page leaves this list as soon as its visit ends, before its `onExit`
  /// runs. See [PlayxBinding.activeScopes].
  static List<PlayxScope> activeScopesOf(PlayxBinding binding) =>
      List<PlayxScope>.unmodifiable(_activeScopes[binding] ?? const []);
}

/// Live (started, not ended) scopes per binding.
final Expando<List<PlayxScope>> _activeScopes =
    Expando<List<PlayxScope>>('PlayxBinding.activeScopes');

/// Maps a [PlayxPage] element to its state, so [PlayxScope.of] works with the
/// context passed to binding callbacks (which is the page's own context, above
/// the [_PlayxScopeProvider]), even after the element is unmounted.
final Expando<_PlayxPageState> _pageOfElement =
    Expando<_PlayxPageState>('PlayxPage');

class _PlayxScopeProvider extends InheritedWidget {
  const _PlayxScopeProvider({required this.scope, required super.child});

  final PlayxScope scope;

  @override
  bool updateShouldNotify(_PlayxScopeProvider oldWidget) =>
      !identical(scope, oldWidget.scope);
}
