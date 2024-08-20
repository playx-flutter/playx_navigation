import 'package:flutter/src/widgets/framework.dart';
import 'package:playx_navigation/playx_navigation.dart';

class ProductsBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState state) async {
    // Handle on Enter
    print('ProductsBinding onEnter');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Handle On Exit
    print('ProductsBinding onExit');
  }
}
