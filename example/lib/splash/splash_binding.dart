import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

class SplashBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState? state) async {
    // Handle on Enter
    print('PlayxNavigation: Splash onEnter');
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state) async {
    print('PlayxNavigation: Splash onReEnter');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Handle On Exit
    print('PlayxNavigation: Splash onExit');
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    // Handle On Hidden
    print('PlayxNavigation: Splash onHidden');
  }
}
