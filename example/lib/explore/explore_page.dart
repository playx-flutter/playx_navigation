import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/navigation/routes.dart';
import 'package:playx_navigation_example/products/product.dart';

/// Explore page — acts as a second tab that can also navigate to product details.
///
/// Tests:
/// - Branch switching lifecycle (Home ↔ Explore ↔ Products → onHidden/onReEnter)
/// - Cross-branch deep link: navigate from Explore to Product Details in Products branch
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final featuredProducts = List.generate(
      5,
      (i) => Product(
        id: 100 + i,
        name: 'Featured #${100 + i}',
        description: 'A featured product from the explore tab',
        imageUrl: 'https://picsum.photos/200/300?random=${100 + i}',
        price: 200.0 + i * 10,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Test: Navigate to Explore's own details child route ---
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Featured Products (Explore Details)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...featuredProducts.map((item) => Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text('\$${item.price}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Push Explore's own details child route
                    // Tests: explore.onHidden → exploreDetails.onEnter
                    PlayxNavigation.toNamed(
                      Routes.exploreDetails,
                      pathParameters: {'id': item.id.toString()},
                      extra: item,
                    );
                  },
                ),
              )),

          const SizedBox(height: 24),

          // --- Test: Navigate to Products tab directly ---
          ElevatedButton.icon(
            onPressed: () {
              // Tests: Branch switch → explore.onHidden, products.onEnter (or onReEnter)
              PlayxNavigation.offAllNamed(Routes.products);
            },
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Switch to Products Tab'),
          ),

          const SizedBox(height: 12),

          // --- Test: Deep link to Product Details in Products branch ---
          ElevatedButton.icon(
            onPressed: () {
              // Tests:
              // - Products page mounted as backstack → deferred onEnter (pending)
              // - Details page is top → Details.onEnter fires immediately
              final product = Product(
                id: 42,
                name: 'Deep Link Product',
                description: 'Navigated from Explore to Products Details',
                imageUrl: 'https://picsum.photos/200/300?random=42',
                price: 999.0,
              );
              PlayxNavigation.toNamed(
                Routes.productDetails,
                pathParameters: {'id': product.id.toString()},
                extra: product,
              );
            },
            icon: const Icon(Icons.link),
            label: const Text('Deep Link → Product Details (cross-branch)'),
          ),
        ],
      ),
    );
  }
}
