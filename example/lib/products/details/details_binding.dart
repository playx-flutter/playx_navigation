import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:playx_navigation/playx_navigation.dart';

class DetailsBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    // Handle on Enter
    log('Product Details onEnter');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Handle On Exit
    log('Product Details onExit');
  }
}
