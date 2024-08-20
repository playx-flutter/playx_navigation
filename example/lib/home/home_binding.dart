import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

class HomeBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    // Handle on Enter
    print('Home onEnter');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Handle On Exit
    print('Home onExit');
  }
}
