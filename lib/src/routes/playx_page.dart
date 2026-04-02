import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation/src/binding/playx_page_state.dart';

/// An internal widget that wraps a route's content and manages the
/// [PlayxBinding] lifecycle via standard widget lifecycle methods.
///
/// - [initState]: Fires [PlayxBinding.onEnter] and **blocks the child from
///   building** until it completes. This guarantees that any dependencies
///   registered in `onEnter` (e.g., GetX controllers) are available before
///   the page's `build` method runs.
/// - [dispose]: Fires [PlayxBinding.onExit] when the page is removed from the tree.
///
/// This ensures `onEnter` fires exactly once per route entry, and `onExit`
/// fires exactly once when the route is truly removed (not just hidden in a
/// [StatefulShellRoute] branch).
class PlayxPage extends StatefulWidget {
  final PlayxBinding binding;
  final GoRouterState state;
  final Widget child;

  const PlayxPage({
    super.key,
    required this.binding,
    required this.state,
    required this.child,
  });

  @override
  State<PlayxPage> createState() => _PlayxPageState();
}

class _PlayxPageState extends State<PlayxPage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    widget.binding.currentState = PlayxPageState.enter;
    await widget.binding.onEnter(context, widget.state);
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    widget.binding.onExit(context);
    widget.binding.currentState = PlayxPageState.exit;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}
