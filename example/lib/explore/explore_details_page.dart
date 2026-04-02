import 'package:flutter/material.dart';
import 'package:playx_navigation_example/products/product.dart';

/// Explore Details page — shows details for items from the Explore tab.
class ExploreDetailsPage extends StatelessWidget {
  final Product? product;
  const ExploreDetailsPage({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Details')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              product?.name ?? 'Unknown',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              product?.description ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${product?.price ?? '-'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
