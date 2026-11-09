import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../routes/playx_page.dart';

/// Runtime breadcrumb labels set by live pages, keyed by the page's matched
/// location. Internal; use `PlayxNavigation.setBreadcrumbLabel` or
/// [PlayxBreadcrumbLabel].
class PlayxBreadcrumbLabels extends ChangeNotifier {
  PlayxBreadcrumbLabels._();

  /// The shared registry.
  static final PlayxBreadcrumbLabels instance = PlayxBreadcrumbLabels._();

  final Map<String, ({String label, Object owner})> _labels = {};
  Listenable? _router;

  /// Also notifies when [router] (the router delegate) changes, so one
  /// listenable covers navigation and label changes. Router notifications can
  /// arrive mid-build, so they are deferred like label changes.
  void attachRouter(Listenable router) {
    if (identical(_router, router)) return;
    _router?.removeListener(_notify);
    _router = router;
    router.addListener(_notify);
  }

  final Set<PlayxScope> _cleanupRegistered = {};
  bool _notifyScheduled = false;

  /// The runtime label for [location], if any.
  String? operator [](String location) => _labels[location]?.label;

  /// Sets (or with `null`, clears) the label of [location] for [owner].
  void set(String location, String? label, Object owner) {
    if (label == null) {
      clear(location, owner);
      return;
    }
    final existing = _labels[location];
    if (existing?.label == label && identical(existing?.owner, owner)) return;
    _labels[location] = (label: label, owner: owner);
    _notify();
  }

  /// Clears the label of [location] if it was set by [owner], so a page that
  /// goes away never removes a label set by a newer page at the same location.
  void clear(String location, Object owner) {
    final existing = _labels[location];
    if (existing == null || !identical(existing.owner, owner)) return;
    _labels.remove(location);
    _notify();
  }

  /// Sets the label of the page [context] belongs to.
  ///
  /// The label is removed when the page's [PlayxScope] is disposed. Pages
  /// without a scope (no binding / controller) keep it until it is cleared
  /// with `null`; prefer [PlayxBreadcrumbLabel] there.
  void setFor(BuildContext context, String? label) {
    final scope = PlayxScope.maybeOf(context);
    final location = scope?.state.matchedLocation ?? _locationOf(context);
    if (location == null) {
      throw StateError(
        'setBreadcrumbLabel must be called with a context inside a page '
        '(a binding callback context or a widget below a route).',
      );
    }
    final Object owner = scope ?? location;
    set(location, label, owner);
    if (scope != null && !scope.isDisposed && _cleanupRegistered.add(scope)) {
      scope.onDispose(() {
        _cleanupRegistered.remove(scope);
        clear(location, scope);
      });
    }
  }

  static String? _locationOf(BuildContext context) {
    try {
      return GoRouterState.of(context).matchedLocation;
    } catch (_) {
      return null;
    }
  }

  void _notify() {
    // Labels are often set while building (PlayxBreadcrumbLabel); breadcrumb
    // widgets must not be marked dirty mid-build, so notify after the frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_notifyScheduled) return;
      _notifyScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notifyScheduled = false;
        notifyListeners();
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    } else {
      notifyListeners();
    }
  }
}

/// Sets the breadcrumb label of the page it is placed in, while it is
/// mounted. Rebuild it with a new [label] to update the breadcrumb.
///
/// Use it for labels that depend on loaded data:
///
/// ```dart
/// Obx(() => PlayxBreadcrumbLabel(label: controller.job.value?.title))
/// ```
///
/// While the page stays in the stack (hidden), its label is also used for
/// its crumb on child pages: `Jobs > Plumbing repair > Edit`. A `null` label
/// falls back to the route's label.
class PlayxBreadcrumbLabel extends StatefulWidget {
  /// Creates a label for the enclosing page.
  const PlayxBreadcrumbLabel({super.key, required this.label, this.child});

  /// The label, or `null` to use the route's label.
  final String? label;

  /// Optional child; defaults to an empty box.
  final Widget? child;

  @override
  State<PlayxBreadcrumbLabel> createState() => _PlayxBreadcrumbLabelState();
}

class _PlayxBreadcrumbLabelState extends State<PlayxBreadcrumbLabel> {
  String? _location;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = PlayxScope.maybeOf(context)?.state.matchedLocation ??
        PlayxBreadcrumbLabels._locationOf(context);
    if (location != _location) {
      final previous = _location;
      if (previous != null) {
        PlayxBreadcrumbLabels.instance.clear(previous, this);
      }
      _location = location;
    }
    _apply();
  }

  @override
  void didUpdateWidget(PlayxBreadcrumbLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label) _apply();
  }

  void _apply() {
    final location = _location;
    if (location == null) return;
    PlayxBreadcrumbLabels.instance.set(location, widget.label, this);
  }

  @override
  void dispose() {
    final location = _location;
    if (location != null) PlayxBreadcrumbLabels.instance.clear(location, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
