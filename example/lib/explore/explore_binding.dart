import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

class ExploreBinding extends PlayxBinding {
  @override
  Future<void> onInitApp() async {
    print('PlayxNavigation: ExploreBinding onInitApp');
  }

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    print('PlayxNavigation: Explore onEnter');
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state,
      bool wasPoppedAndReentered) async {
    print(
        'PlayxNavigation: Explore onReEnter wasPoppedAndReentered:$wasPoppedAndReentered');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    print('PlayxNavigation: Explore onExit');
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    print('PlayxNavigation: Explore onHidden');
  }
}
