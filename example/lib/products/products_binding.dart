import 'package:flutter/src/widgets/framework.dart';
import 'package:playx_navigation/playx_navigation.dart';

class ProductsBinding extends PlayxBinding {
  @override
  Future<void> onEnter(BuildContext context, GoRouterState? state) async {
    // Handle on Enter
    print('PlayxNavigation: ProductsBinding onEnter');
  }

  @override
  Future<void> onReEnter(BuildContext context, GoRouterState? state) async {
    print('PlayxNavigation: ProductsBinding onReEnter');
  }

  @override
  Future<void> onExit(BuildContext context) async {
    // Handle On Exit
    print('PlayxNavigation: ProductsBinding onExit');
  }

  @override
  Future<void> onHidden(BuildContext context) async {
    // Handle On Hidden
    print('PlayxNavigation: ProductsBinding onHidden');
  }
}
