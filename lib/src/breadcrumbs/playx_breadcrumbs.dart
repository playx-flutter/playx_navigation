import 'package:flutter/material.dart';

import '../playx_navigation.dart';
import 'playx_breadcrumb.dart';

/// Rebuilds [builder] with the current breadcrumb trail whenever the route or
/// a runtime breadcrumb label changes.
///
/// Use it to feed your own breadcrumb widget:
///
/// ```dart
/// PlayxBreadcrumbsBuilder(
///   mode: PlayxBreadcrumbMode.shellBranch,
///   builder: (context, items) => BreadcrumbHeader(
///     items: [
///       for (final item in items)
///         BreadcrumbItem(title: item.label, onTap: item.navigate),
///     ],
///   ),
/// )
/// ```
class PlayxBreadcrumbsBuilder extends StatelessWidget {
  /// Creates a builder.
  const PlayxBreadcrumbsBuilder({
    super.key,
    this.mode = PlayxBreadcrumbMode.hierarchy,
    this.rootLocation,
    required this.builder,
  });

  /// Which pages the trail shows.
  final PlayxBreadcrumbMode mode;

  /// A location prepended to the trail in [PlayxBreadcrumbMode.hierarchy],
  /// e.g. `/home`, unless it is already part of it.
  final String? rootLocation;

  /// Builds the UI from the trail.
  final Widget Function(BuildContext context, List<PlayxBreadcrumbItem> items)
      builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayxNavigation.breadcrumbsListenable,
      builder: (context, _) => builder(
        context,
        PlayxNavigation.breadcrumbs(
          context,
          mode: mode,
          rootLocation: rootLocation,
        ),
      ),
    );
  }
}

/// A breadcrumb trail connected to navigation: `Jobs > Job #5 > Edit`.
///
/// Items come from the routes' `breadcrumb` labels (and bindings' and runtime
/// labels); tapping one navigates to it, the current page is not tappable.
/// Long trails collapse to `first > … > last items`, and the `…` opens a menu
/// with the hidden items.
///
/// Rebuilds on every navigation, so it can live in a persistent shell header.
///
/// ```dart
/// PlayxBreadcrumbs(mode: PlayxBreadcrumbMode.shellBranch)
/// PlayxBreadcrumbs(rootLocation: '/home')
/// ```
///
/// Use [itemBuilder] / [separator] to match your design, or
/// [PlayxBreadcrumbsBuilder] for a fully custom widget.
class PlayxBreadcrumbs extends StatelessWidget {
  /// Creates a breadcrumb trail.
  const PlayxBreadcrumbs({
    super.key,
    this.mode = PlayxBreadcrumbMode.hierarchy,
    this.rootLocation,
    this.maxItems = 4,
    this.collapsedMenu = true,
    this.hideIfSingle = false,
    this.separator,
    this.spacing = 8,
    this.style,
    this.currentStyle,
    this.itemBuilder,
    this.ellipsisBuilder,
  }) : assert(maxItems == null || maxItems >= 2, 'maxItems must be >= 2');

  /// Which pages the trail shows.
  final PlayxBreadcrumbMode mode;

  /// A location prepended in [PlayxBreadcrumbMode.hierarchy], e.g. `/home`.
  final String? rootLocation;

  /// When the trail has more items, it shows the first item, `…`, and the
  /// last `maxItems - 1` items. `null` never collapses.
  final int? maxItems;

  /// Whether tapping `…` opens a menu with the hidden items.
  final bool collapsedMenu;

  /// Whether to render nothing when the trail has one item or less.
  final bool hideIfSingle;

  /// The widget between items. Defaults to a chevron icon.
  final Widget? separator;

  /// Space between items and separators.
  final double spacing;

  /// Text style of tappable items. Defaults to `bodyMedium` in
  /// `onSurfaceVariant`.
  final TextStyle? style;

  /// Text style of the current item. Defaults to `bodyMedium` in `onSurface`.
  final TextStyle? currentStyle;

  /// Builds an item's content (e.g. your own text widget). Taps are handled
  /// by [PlayxBreadcrumbs]; check `item.isCurrent` for styling.
  final Widget Function(BuildContext context, PlayxBreadcrumbItem item)?
      itemBuilder;

  /// Builds the `…` content shown for [hidden] items.
  final Widget Function(BuildContext context, List<PlayxBreadcrumbItem> hidden)?
      ellipsisBuilder;

  @override
  Widget build(BuildContext context) {
    return PlayxBreadcrumbsBuilder(
      mode: mode,
      rootLocation: rootLocation,
      builder: (context, items) {
        if (items.isEmpty || (hideIfSingle && items.length <= 1)) {
          return const SizedBox.shrink();
        }

        final max = maxItems;
        final collapse = max != null && items.length > max;
        final visible = collapse
            ? <PlayxBreadcrumbItem?>[
                items.first,
                null, // ellipsis
                ...items.sublist(items.length - (max - 1)),
              ]
            : items;
        final hidden = collapse
            ? items.sublist(1, items.length - (max - 1))
            : const <PlayxBreadcrumbItem>[];

        final children = <Widget>[];
        for (var i = 0; i < visible.length; i++) {
          final item = visible[i];
          children.add(
              item == null ? _ellipsis(context, hidden) : _item(context, item));
          if (i < visible.length - 1) children.add(_separator(context));
        }

        // Transparent Material so the items' InkWells work even when the
        // breadcrumbs sit outside a Scaffold (e.g. a header above the router).
        return Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: spacing,
              children: children,
            ),
          ),
        );
      },
    );
  }

  TextStyle? _style(BuildContext context, {required bool current}) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium;
    return current
        ? currentStyle ?? base?.copyWith(color: theme.colorScheme.onSurface)
        : style ?? base?.copyWith(color: theme.colorScheme.onSurfaceVariant);
  }

  Widget _item(BuildContext context, PlayxBreadcrumbItem item) {
    final content = itemBuilder?.call(context, item) ??
        Text(item.label, style: _style(context, current: item.isCurrent));
    if (item.isCurrent) return content;
    return InkWell(
      onTap: item.navigate,
      borderRadius: BorderRadius.circular(4),
      child: content,
    );
  }

  Widget _separator(BuildContext context) {
    return separator ??
        Icon(
          Icons.keyboard_arrow_right,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }

  Widget _ellipsis(BuildContext context, List<PlayxBreadcrumbItem> hidden) {
    final content = ellipsisBuilder?.call(context, hidden) ??
        Text('…', style: _style(context, current: false));
    if (!collapsedMenu) return content;
    return Builder(
      builder: (ellipsisContext) => InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _showHiddenMenu(ellipsisContext, hidden),
        child: content,
      ),
    );
  }

  /// Shows [hidden] items in a menu below the ellipsis.
  ///
  /// Works even when the breadcrumbs are above the router's Navigator (e.g. in
  /// `MaterialApp.router`'s `builder`), by falling back to the root navigator
  /// and positioning the menu from global coordinates.
  Future<void> _showHiddenMenu(
    BuildContext context,
    List<PlayxBreadcrumbItem> hidden,
  ) async {
    final navigator = Navigator.maybeOf(context) ??
        PlayxNavigation.rootNavigatorKey.currentState;
    // The overlay's context is below the navigator, so showMenu finds both.
    final menuContext = navigator?.overlay?.context;
    final anchor = context.findRenderObject();
    if (menuContext == null || anchor is! RenderBox) return;
    final overlay = menuContext.findRenderObject();
    if (overlay is! RenderBox) return;

    final origin = overlay.localToGlobal(Offset.zero);
    final start = anchor.localToGlobal(Offset(0, anchor.size.height)) - origin;
    final selected = await showMenu<PlayxBreadcrumbItem>(
      context: menuContext,
      position: RelativeRect.fromLTRB(
        start.dx,
        start.dy,
        overlay.size.width - start.dx,
        overlay.size.height - start.dy,
      ),
      items: [
        for (final item in hidden)
          PopupMenuItem(value: item, child: Text(item.label)),
      ],
    );
    selected?.navigate();
  }
}
