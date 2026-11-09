import 'package:flutter/foundation.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/products/product.dart';

/// Controller of the Explore Details page — created per page by
/// `PlayxRoute<ExploreDetailsController>(controller: ...)`, no binding needed.
///
/// Uses [PlayxPageLifecycle] to react to its page's lifecycle.
class ExploreDetailsController with PlayxPageLifecycle {
  ExploreDetailsController({required this.id, Product? product})
      : product = ValueNotifier<Product?>(product);

  final int id;
  final ValueNotifier<Product?> product;

  @override
  Future<void> onPageEnter(GoRouterState state) async {
    debugPrint('PlayxNavigation: Explore Details #$id onPageEnter');
    // `extra` is missing after a web refresh or a deep link: load by id.
    if (product.value == null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      product.value = Product(
        id: id,
        name: 'Featured #$id',
        description: 'Loaded by id (no extra)',
        price: 200.0 + (id - 100) * 10,
      );
    }
  }

  @override
  void onPageHidden() =>
      debugPrint('PlayxNavigation: Explore Details #$id onPageHidden');

  @override
  void onPageReEnter(GoRouterState? state, bool wasPoppedAndReentered) =>
      debugPrint('PlayxNavigation: Explore Details #$id onPageReEnter '
          'wasPoppedAndReentered:$wasPoppedAndReentered');

  @override
  void onPageExit() =>
      debugPrint('PlayxNavigation: Explore Details #$id onPageExit');

  void dispose() {
    debugPrint('PlayxNavigation: Explore Details #$id disposed');
    product.dispose();
  }
}
