import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation/src/binding/playx_page_state.dart';

class PlayxPage extends StatefulWidget {
  final PlayxBinding binding;
  final Widget child;
  const PlayxPage({super.key, required this.binding, required this.child});

  @override
  State<PlayxPage> createState() => _PlayxPageState();
}

class _PlayxPageState extends State<PlayxPage> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.binding.shouldExecuteOnExit) {
      widget.binding.onExit(
        context,
      );
      widget.binding.currentState = PlayxPageState.exit;
    }
  }
}
