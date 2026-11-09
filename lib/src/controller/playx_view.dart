import 'package:flutter/widgets.dart';

import '../models/playx_page_config.dart';
import '../routes/playx_page.dart';

/// A widget that gets its page's controller of type [T], like GetX's
/// `GetView<T>`, but scoped to the page instead of a global registry.
///
/// Use it for page views and for child widgets in separate files
/// (`BuildList`, `BuildListItem`...): any widget inside the page's tree
/// resolves the same page's controller.
///
/// The controller is looked up in this order:
/// 1. the page's [PlayxScope] (a `PlayxRoute<T>(controller: ...)` controller,
///    or a value the binding stored with `PlayxScope.of(context).put`),
///    including values whose type is a subtype of [T];
/// 2. [PlayxPageConfig.findController] (e.g. GetX by `scope.id` tag).
///
/// ```dart
/// class JobsView extends PlayxView<JobsController> {
///   const JobsView({super.key});
///
///   @override
///   Widget buildView(BuildContext context, JobsController controller) {
///     return Scaffold(
///       body: const BuildJobsList(),
///       floatingActionButton: FloatingActionButton(
///         onPressed: controller.refresh,
///       ),
///     );
///   }
/// }
/// ```
///
/// Safe with `const` constructors and in callbacks such as `onPressed`, since
/// the controller is resolved from the context on every build and passed in.
///
/// Dialogs and bottom sheets are shown above the page; wrap their content in
/// [PlayxScopeProvider] to make the controller reachable there.
abstract class PlayxView<T extends Object> extends StatelessWidget {
  /// Creates a view.
  const PlayxView({super.key});

  /// Builds the view with its page's [controller].
  Widget buildView(BuildContext context, T controller);

  @override
  Widget build(BuildContext context) =>
      buildView(context, context.controller<T>());
}

/// Access to the current page's controllers from any widget inside the page.
extension PlayxControllerContext on BuildContext {
  /// Returns the current page's controller of type [T].
  ///
  /// Same lookup as [PlayxView]. Throws a [StateError] if none is found.
  T controller<T extends Object>() {
    final controller = maybeController<T>();
    if (controller != null) return controller;
    final scope = PlayxScope.maybeOf(this);
    throw StateError(
      scope == null
          ? 'No $T found: this widget is not inside a page with a binding or '
              'controller. For dialogs and bottom sheets, wrap the content in '
              'PlayxScopeProvider(scope: PlayxScope.of(context), child: ...).'
          : 'No $T found for this page (${scope.binding.runtimeType}). Add '
              'controller: to the PlayxRoute, store it from the binding with '
              'PlayxScope.of(context).put<$T>(...), or configure '
              'PlayxPageConfig.findController.',
    );
  }

  /// Like [controller], but returns `null` when no controller is found, e.g.
  /// in a `shellBuilder` before the page is initialized.
  T? maybeController<T extends Object>() {
    final scope = PlayxScope.maybeOf(this);
    if (scope == null) return null;
    final value = scope.maybeGet<T>();
    if (value != null) return value;
    final find = PlayxPageConfigProvider.read(this)?.findController;
    return find?.call<T>(scope);
  }
}
