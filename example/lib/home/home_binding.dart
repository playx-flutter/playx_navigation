import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

class HomeBinding extends PlayxBinding {
  @override
  Future<void> onInitApp() async {
    print('PlayxNavigation: HomeBinding onInitApp');
  }

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    print('PlayxNavigation: Home onEnter');
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state,
      bool wasPoppedAndReentered) async {
    print(
        'PlayxNavigation: Home onReEnter wasPoppedAndReentered:$wasPoppedAndReentered');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    print('PlayxNavigation: Home onExit');
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    print('PlayxNavigation: Home onHidden');
  }
}
