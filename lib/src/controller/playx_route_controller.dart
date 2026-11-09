import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../binding/playx_binding.dart';
import '../models/playx_page_config.dart';
import '../routes/playx_page.dart';

/// Creates the controller of a page. Called once per page visit, when the page
/// is entered (after every `onInitApp` completed).
typedef PlayxControllerBuilder<T extends Object> = T Function(
  BuildContext context,
  GoRouterState state,
);

/// Internal: the controller configuration of a `PlayxRoute<T>`.
///
/// Keeps the static type [T], so the controller is stored and registered under
/// [T] (not under `Object`) and disposed with a typed callback.
class PlayxRouteController<T extends Object> {
  /// Creates the configuration.
  PlayxRouteController(this.create, this.dispose);

  /// Creates the controller.
  final PlayxControllerBuilder<T> create;

  /// Disposes the controller. Optional.
  final void Function(T controller)? dispose;

  /// The binding used for routes that have a controller but no binding.
  /// Created once per route, so the page keeps one visit across rebuilds.
  late final PlayxBinding fallbackBinding = _ControllerOnlyBinding();

  /// Creates the controller, stores it in [scope] under [T], and registers it
  /// with [config]'s `registerController`.
  T createIn(
    BuildContext context,
    GoRouterState state,
    PlayxScope scope,
    PlayxPageConfig? config,
  ) {
    final controller = create(context, state);
    scope.put<T>(controller);
    config?.registerController?.call<T>(controller, scope);
    return controller;
  }

  /// Unregisters [controller] with [config]'s `unregisterController`, then
  /// calls [dispose]. Errors are reported; every step still runs.
  void release(Object controller, PlayxScope scope, PlayxPageConfig? config) {
    final typed = controller as T;
    _guard(() => config?.unregisterController?.call<T>(typed, scope),
        'while unregistering $T');
    _guard(() => dispose?.call(typed), 'while disposing $T');
  }

  static void _guard(void Function() action, String description) {
    try {
      action();
    } catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'playx_navigation',
        context: ErrorDescription(description),
      ));
    }
  }
}

class _ControllerOnlyBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {}
}
