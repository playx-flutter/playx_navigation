import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/navigation/routes.dart';
import 'package:playx_navigation_example/products/product.dart';

/// Home page — the default tab. Has navigation actions to test various
/// lifecycle scenarios from the home context.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Lifecycle Test Actions'),
          const SizedBox(height: 8),

          // --- Test: Deep link to Product Details from Home ---
          // This navigates to /products/:id.
          // Products page mounts as backstack → onEnter DEFERRED.
          // Details page is top → onEnter fires immediately.
          ElevatedButton.icon(
            onPressed: () {
              final product = Product(
                id: 1,
                name: 'Product #1',
                description: 'Deep linked from Home tab',
                imageUrl: 'https://picsum.photos/200/300?random=1',
                price: 100.0,
              );
              PlayxNavigation.toNamed(
                Routes.productDetails,
                pathParameters: {'id': product.id.toString()},
                extra: product,
              );
            },
            icon: const Icon(Icons.link),
            label: const Text('Deep Link → Product Details'),
          ),
          _hint('Products.onEnter deferred (backstack), '
              'Details.onEnter fires immediately'),

          const SizedBox(height: 16),

          // --- Test: Navigate to Products tab ---
          // Branch switch → home.onHidden, products.onEnter (or onReEnter)
          ElevatedButton.icon(
            onPressed: () {
              PlayxNavigation.offAllNamed(Routes.products);
            },
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Go to Products Tab'),
          ),
          _hint('home.onHidden → products.onEnter/onReEnter(false)'),

          const SizedBox(height: 16),

          // --- Test: Navigate to Explore tab ---
          ElevatedButton.icon(
            onPressed: () {
              PlayxNavigation.offAllNamed(Routes.explore);
            },
            icon: const Icon(Icons.explore),
            label: const Text('Go to Explore Tab'),
          ),
          _hint('home.onHidden → explore.onEnter/onReEnter(false)'),

          const SizedBox(height: 24),
          _sectionTitle('Binding Registry'),
          const SizedBox(height: 8),

          // --- Test: Binding lookup ---
          ElevatedButton.icon(
            onPressed: () {
              final bindings = PlayxNavigation.bindings;
              final msg = 'Found ${bindings.length} bindings:\n'
                  '${bindings.map((b) => '  • ${b.runtimeType}').join('\n')}';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(msg), duration: const Duration(seconds: 3)),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('Show All Registered Bindings'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
