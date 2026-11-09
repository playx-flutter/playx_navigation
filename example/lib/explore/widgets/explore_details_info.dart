import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/explore/explore_details_controller.dart';
import 'package:playx_navigation_example/products/product.dart';

/// A child widget in its own file: also a [PlayxView], so it gets the same
/// page's controller without passing it down.
class ExploreDetailsInfo extends PlayxView<ExploreDetailsController> {
  const ExploreDetailsInfo({super.key});

  @override
  Widget buildView(BuildContext context, ExploreDetailsController controller) {
    return ValueListenableBuilder<Product?>(
      valueListenable: controller.product,
      builder: (context, product, _) {
        if (product == null) return const CircularProgressIndicator();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(product.name,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(product.description,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('\$${product.price}',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        );
      },
    );
  }
}
