import 'package:flutter/material.dart';
import 'package:playx_navigation_example/products/product.dart';

class ProductDetailsPage extends StatelessWidget {
  final Product product;
  const ProductDetailsPage({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                product.price.toString(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ));
  }
}
