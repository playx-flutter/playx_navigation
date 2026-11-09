import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../playx_navigation.dart';
import '../routes/playx_route.dart';
import 'playx_breadcrumb_labels.dart';

/// Builds the breadcrumb label of a route. Return `null` to leave the route
/// out of the trail (the trail still continues to its parents).
///
/// [context] is the context of the widget showing the breadcrumbs, so
/// localized strings work, e.g. `context.l10n.jobs`.
typedef PlayxBreadcrumbLabelBuilder = String? Function(
  BuildContext context,
  GoRouterState state,
);

/// Which pages a breadcrumb trail shows.
enum PlayxBreadcrumbMode {
  /// The current page and its parents, from the route tree and paths (the
  /// same parent rule as `PlayxNavigation.back()`): `Home > Jobs > Job > Edit`.
  /// Independent of how the user got there, so it survives web refreshes and
  /// deep links.
  hierarchy,

  /// Like [hierarchy], but starting at the root page of the current shell
  /// branch: `Jobs > Job > Edit`. Outside a shell it behaves like [hierarchy].
  shellBranch,

  /// The pages actually in the navigation stack, bottom to top. Depends on
  /// how the user navigated and resets on web refresh. Tapping a crumb pops
  /// back to that page.
  history,
}

/// One entry of a breadcrumb trail.
@immutable
class PlayxBreadcrumbItem {
  /// Creates an item.
  const PlayxBreadcrumbItem({
    required this.label,
    required this.location,
    required this.state,
    required this.isCurrent,
    required this.mode,
  });

  /// The text to show.
  final String label;

  /// The page's matched location, e.g. `/jobs/5`.
  final String location;

  /// The page's state (path parameters, name...). `extra` is only available
  /// for the current page and, in [PlayxBreadcrumbMode.history], for pages in
  /// the stack.
  final GoRouterState state;

  /// Whether this is the current page (the last item).
  final bool isCurrent;

  /// The mode this item was resolved with; decides what [navigate] does.
  final PlayxBreadcrumbMode mode;

  /// Navigates to this item's page: pops back to it in
  /// [PlayxBreadcrumbMode.history], otherwise goes to [location].
  /// Does nothing for the current page.
  void navigate() {
    if (isCurrent) return;
    if (mode == PlayxBreadcrumbMode.history &&
        PlayxNavigation.playxRouter.popToPage(state.pageKey)) {
      return;
    }
    PlayxNavigation.goRouter.go(location);
  }

  @override
  String toString() => 'PlayxBreadcrumbItem($label, $location'
      '${isCurrent ? ', current' : ''})';
}

/// Resolves the breadcrumb trail of the current page.
List<PlayxBreadcrumbItem> resolveBreadcrumbs(
  BuildContext context, {
  required PlayxBreadcrumbMode mode,
  String? rootLocation,
}) {
  final router = PlayxNavigation.playxRouter;
  final current = router.stateOrNull;
  if (current == null) return const [];

  final List<GoRouterState> states;
  if (mode == PlayxBreadcrumbMode.history) {
    states = router.pageStack;
  } else {
    states = <GoRouterState>[];
    final visited = <String>{};
    GoRouterState? state = current;
    while (state != null &&
        states.length < 20 &&
        visited.add(state.matchedLocation)) {
      states.insert(0, state);
      if (mode == PlayxBreadcrumbMode.shellBranch &&
          router.isShellBranchRoot(state.matchedLocation)) {
        break;
      }
      final parent = router.parentOf(state);
      state = parent == null ? null : router.stateFor(parent);
    }
    if (mode == PlayxBreadcrumbMode.hierarchy && rootLocation != null) {
      final root = router.stateFor(rootLocation);
      if (root != null && !visited.contains(root.matchedLocation)) {
        states.insert(0, root);
      }
    }
  }

  return [
    for (final state in states)
      if (_labelFor(context, state) case final label?)
        PlayxBreadcrumbItem(
          label: label,
          location: state.matchedLocation,
          state: state,
          isCurrent: state.pageKey == current.pageKey &&
              state.matchedLocation == current.matchedLocation,
          mode: mode,
        ),
  ];
}

/// Label precedence: runtime label of a live page, then the route's
/// `breadcrumb`, then its binding's `breadcrumb`.
String? _labelFor(BuildContext context, GoRouterState state) {
  final runtime = PlayxBreadcrumbLabels.instance[state.matchedLocation];
  if (runtime != null) return runtime;
  final route = state.topRoute;
  if (route is! PlayxRoute) return null;
  return route.breadcrumb?.call(context, state) ??
      route.binding?.breadcrumb(context, state);
}
