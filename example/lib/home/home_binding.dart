import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

class HomeBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    // Handle on Enter
    print('PlayxNavigation: Home onEnter');
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state,
      bool wasPoppedAndReentered) async {
    print(
        'PlayxNavigation: Home onReEnter isStillInNavigationStack :$wasPoppedAndReentered');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Handle On Exit
    print('PlayxNavigation: Home onExit');
  }

  @override
  Future<void> onHidden(
    BuildContext context,
  ) async {
    // Handle On Hidden
    print('PlayxNavigation: Home onHidden');
  }
}
