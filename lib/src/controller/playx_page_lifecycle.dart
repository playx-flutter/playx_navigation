import 'dart:async';

import 'package:go_router/go_router.dart';

/// Optional page-lifecycle hooks for a route controller.
///
/// Mix this into a controller created with `PlayxRoute<T>(controller: ...)`
/// to react to its page's lifecycle from the controller itself, without
/// writing a binding. It works alongside any base class, e.g. `GetxController`
/// (the `onPage*` names don't clash with `onInit` / `onReady` / `onClose`).
///
/// Hooks run after the route binding's matching callback (if the route also
/// has a binding), in the page's lifecycle queue, so they never overlap.
///
/// ```dart
/// class JobsController extends GetxController with PlayxPageLifecycle {
///   @override
///   void onPageReEnter(GoRouterState? state, bool wasPoppedAndReentered) {
///     if (pagingController.itemList?.isNotEmpty ?? false) tour.start();
///   }
///
///   @override
///   void onPageHidden() => tour.dismiss();
/// }
/// ```
mixin PlayxPageLifecycle {
  /// Called once when the page is entered, after the controller is created
  /// and after the binding's `onEnter`.
  ///
  /// While it runs the page shows its loading widget (unless the route uses
  /// `waitForBinding: false`). A good place to load data, e.g. by id when
  /// `extra` is missing after a web refresh.
  FutureOr<void> onPageEnter(GoRouterState state) {}

  /// Called when another page covers this one (push, branch switch) while it
  /// stays in the stack.
  FutureOr<void> onPageHidden() {}

  /// Called when this page becomes visible again after being hidden.
  ///
  /// [wasPoppedAndReentered] is `true` when the pages above it were removed
  /// (pop), and `false` for a branch switch.
  FutureOr<void> onPageReEnter(
    GoRouterState? state,
    bool wasPoppedAndReentered,
  ) {}

  /// Called when the page is removed, after the binding's `onExit` and right
  /// before the controller is disposed.
  FutureOr<void> onPageExit() {}
}
