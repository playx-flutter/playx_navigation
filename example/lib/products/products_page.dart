import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/navigation/routes.dart';
import 'package:playx_navigation_example/products/product.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final products = List.generate(
      10,
      (e) => Product(
            id: e,
            name: 'Product $e',
            description: 'Description of product $e',
            imageUrl: 'https://picsum.photos/200/300?random=$e',
            price: 100.0 + e,
          ));

  @override
  void initState() {
    super.initState();
    // print('PlayxNavigation: Products onInit');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final item = products[index];
          return InkWell(
            onTap: () {
              PlayxNavigation.toNamed(Routes.details,
                  pathParameters: {
                    'id': item.id.toString(),
                  },
                  extra: item);
            },
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      item.imageUrl ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12,
                    ),
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 12.0,
                      left: 12,
                      bottom: 8,
                    ),
                    child: Text(
                      item.description,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    // print('PlayxNavigation: Products onDispose');
  }
}
