import 'package:flutter/widgets.dart';

import 'playx_breadcrumb.dart';

/// Builds a browser tab title from the breadcrumb trail.
///
/// Pass it to `PlayxNavigationBuilder(pageTitle: ...)`. The title follows the
/// current page, reusing the labels you already declared for breadcrumbs
/// (route `breadcrumb`, binding `breadcrumb`, `PlayxBreadcrumbLabel`):
///
/// ```dart
/// PlayxNavigationBuilder(
///   router: router,
///   pageTitle: const PlayxPageTitle(appName: 'Jobs Dashboard'),
///   builder: (context) => const MyApp(),
/// )
/// // On /jobs/5 once the job loaded: "Plumbing repair · Jobs · Jobs Dashboard"
/// ```
///
/// The title is applied with `SystemChrome.setApplicationSwitcherDescription`,
/// which sets the document title on web (and the task label on Android).
@immutable
class PlayxPageTitle {
  /// Creates a page title configuration.
  const PlayxPageTitle({
    this.appName,
    this.separator = ' · ',
    this.maxItems = 2,
    this.mode = PlayxBreadcrumbMode.hierarchy,
    this.rootLocation,
    this.builder,
  }) : assert(maxItems == null || maxItems >= 1, 'maxItems must be >= 1');

  /// Appended after the page labels, e.g. the app's name. Also used alone
  /// when the current page has no breadcrumb label.
  final String? appName;

  /// Placed between the parts of the title.
  final String separator;

  /// How many breadcrumb labels to include, starting with the current page
  /// and going up to its parents. `null` includes the whole trail.
  final int? maxItems;

  /// Which breadcrumb trail the title is built from.
  final PlayxBreadcrumbMode mode;

  /// A location prepended to the trail in [PlayxBreadcrumbMode.hierarchy].
  final String? rootLocation;

  /// Builds the whole title yourself from the trail (bottom to top). Return
  /// `null` to leave the title unchanged. [context] is inside the app, so
  /// localized strings work.
  final String? Function(BuildContext context, List<PlayxBreadcrumbItem> items)?
      builder;

  /// Computes the title for [items] (the trail, bottom to top), or `null` if
  /// there is nothing to show.
  String? resolve(BuildContext context, List<PlayxBreadcrumbItem> items) {
    final custom = builder;
    if (custom != null) return custom(context, items);

    final labels = items.reversed.map((item) => item.label);
    final parts = <String>[
      ...(maxItems == null ? labels : labels.take(maxItems!)),
      if (appName != null && appName!.isNotEmpty) appName!,
    ];
    return parts.isEmpty ? null : parts.join(separator);
  }
}
