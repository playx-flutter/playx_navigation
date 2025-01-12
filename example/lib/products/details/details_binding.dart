import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

class DetailsBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    // Handle on Enter
    print('PlayxNavigation: Product Details onEnter');
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state,
      bool wasPoppedAndReentered) async {
    print(
        'PlayxNavigation: Product Details onReEnter isStillInNavigationStack:$wasPoppedAndReentered');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Handle On Exit
    print('PlayxNavigation: Product Details onExit');
  }

  @override
  Future<void> onHidden(
    BuildContext context,
  ) async {
    // Handle On Hidden
    print('PlayxNavigation: Product Details onHidden');
  }
}
