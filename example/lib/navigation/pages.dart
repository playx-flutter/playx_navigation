import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/home/home_binding.dart';
import 'package:playx_navigation_example/home/home_page.dart';
import 'package:playx_navigation_example/navigation/routes.dart';
import 'package:playx_navigation_example/products/details/details_binding.dart';
import 'package:playx_navigation_example/products/details/details_page.dart';
import 'package:playx_navigation_example/products/product.dart';
import 'package:playx_navigation_example/products/products_binding.dart';
import 'package:playx_navigation_example/products/products_page.dart';
import 'package:playx_navigation_example/splash/splash_page.dart';

import '../splash/splash_binding.dart';

class AppPages {
  static final GoRouter router = GoRouter(
    initialLocation: Paths.splash,
    debugLogDiagnostics: true,
    routes: [
      PlayxRoute(
        path: Paths.splash,
        name: Routes.splash,
        builder: (context, state) => const SplashPage(),
        binding: SplashBinding(),
      ),
      StatefulShellRoute.indexedStack(
          pageBuilder: (context, state, navigationShell) => CupertinoPage(
                child: Scaffold(
                  body: navigationShell,
                  bottomNavigationBar: BottomNavigationBar(
                      currentIndex: navigationShell.currentIndex,
                      onTap: (index) {
                        navigationShell.goBranch(index);
                      },
                      items: [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.shopping_cart),
                          label: 'Products',
                        ),
                      ]),
                ),
              ),
          branches: [
            PlayxShellBranch(
              name: Routes.home,
              path: Paths.home,
              builder: (context, state) => HomePage(),
              binding: HomeBinding(),
            ),
            PlayxShellBranch(
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
          ])
    ],
  );
}
