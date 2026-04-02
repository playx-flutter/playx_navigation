import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

/// Binding for the Explore Details route — tests the case where navigating
/// to details from a DIFFERENT branch (Explore) pushes a child route
/// in a separate branch context.
class ExploreDetailsBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    final id = state.pathParameters['id'];
    print('PlayxNavigation: Explore Details #$id onEnter');
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state,
      bool wasPoppedAndReentered) async {
    print(
        'PlayxNavigation: Explore Details onReEnter wasPoppedAndReentered:$wasPoppedAndReentered');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    print('PlayxNavigation: Explore Details onExit');
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    print('PlayxNavigation: Explore Details onHidden');
  }
}
