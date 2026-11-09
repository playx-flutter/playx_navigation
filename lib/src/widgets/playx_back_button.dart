import 'package:flutter/material.dart';

import '../playx_navigation.dart';

/// A back button that calls [PlayxNavigation.back]: it pops when possible,
/// otherwise goes to the page's parent.
///
/// Flutter's automatic `AppBar` back button only appears when there is
/// something to pop, so on web it is missing after a refresh, a typed URL or a
/// deep link. Use this as the `leading` widget instead:
///
/// ```dart
/// AppBar(
///   leading: PlayxNavigation.canGoBack ? const PlayxBackButton() : null,
///   title: const Text('Job details'),
/// )
/// ```
///
/// Renders nothing when [PlayxNavigation.canGoBack] is `false`.
class PlayxBackButton extends StatelessWidget {
  /// Creates a back button.
  const PlayxBackButton({super.key, this.color, this.onPressed});

  /// The icon color. Defaults to the [BackButton] default.
  final Color? color;

  /// Called before navigating back, e.g. to save a draft.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!PlayxNavigation.canGoBack) return const SizedBox.shrink();
    return BackButton(
      color: color,
      onPressed: () {
        onPressed?.call();
        PlayxNavigation.back();
      },
    );
  }
}
