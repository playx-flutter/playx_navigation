import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

class DetailsBinding extends PlayxBinding {
  @override
  Future<void> onInitApp() async {
    print('PlayxNavigation: DetailsBinding onInitApp');
  }

  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    final id = state.pathParameters['id'];
    print('PlayxNavigation: Product Details #$id onEnter');
    // Simulate data fetching to show loading widget
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state,
      bool wasPoppedAndReentered) async {
    print(
        'PlayxNavigation: Product Details onReEnter wasPoppedAndReentered:$wasPoppedAndReentered');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    print('PlayxNavigation: Product Details onExit');
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    print('PlayxNavigation: Product Details onHidden');
  }
}
