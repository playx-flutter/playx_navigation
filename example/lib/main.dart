import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/home/home_page.dart';
import 'package:playx_navigation_example/products/details/details_binding.dart';
import 'package:playx_navigation_example/products/details/details_page.dart';
import 'package:playx_navigation_example/products/product.dart';
import 'package:playx_navigation_example/products/products_binding.dart';
import 'package:playx_navigation_example/products/products_page.dart';

import 'home/home_binding.dart';

void main() {
  runApp(const MyApp());
}

abstract class Routes {
  static const home = 'home';
  static const products = 'products';
  static const details = 'productDetails';
}

abstract class Paths {
  static const home = '/home';
  static const products = '/products';
  static const details = ':id';
}

final router = GoRouter(
  initialLocation: Paths.home,
  debugLogDiagnostics: true,
  routes: [
    PlayxRoute(
      path: Paths.home,
      name: Routes.home,
      builder: (context, state) => const HomePage(),
      binding: HomeBinding(),
    ),
    PlayxRoute(
        path: Paths.products,
        name: Routes.products,
        builder: (context, state) => ProductsPage(),
        binding: ProductsBinding(),
        routes: [
          PlayxRoute(
            path: Paths.details,
            name: Routes.details,
            builder: (context, state) =>
                ProductDetailsPage(product: state.extra as Product),
            binding: DetailsBinding(),
          ),
        ]),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PlayxNavigationBuilder(
        router: router,
        builder: (context) {
          return MaterialApp.router(
            title: 'Playx',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            routerDelegate: router.routerDelegate,
            routeInformationParser: router.routeInformationParser,
            routeInformationProvider: router.routeInformationProvider,
            backButtonDispatcher: router.backButtonDispatcher,
          );
        });
  }
}
