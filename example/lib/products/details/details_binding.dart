import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

class DetailsBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState? state) async {
    // Handle on Enter
    log('PlayxNavigation: Product Details onEnter');
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state) async {
    log('PlayxNavigation: Product Details onReEnter');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Handle On Exit
    log('PlayxNavigation: Product Details onExit');
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    // Handle On Hidden
    log('PlayxNavigation: Product Details onHidden');
  }
}
