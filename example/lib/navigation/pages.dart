import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/explore/explore_binding.dart';
import 'package:playx_navigation_example/explore/explore_details_controller.dart';
import 'package:playx_navigation_example/explore/explore_details_page.dart';
import 'package:playx_navigation_example/explore/explore_page.dart';
import 'package:playx_navigation_example/home/home_binding.dart';
import 'package:playx_navigation_example/home/home_page.dart';
import 'package:playx_navigation_example/navigation/routes.dart';
import 'package:playx_navigation_example/products/details/details_binding.dart';
import 'package:playx_navigation_example/products/details/details_page.dart';
import 'package:playx_navigation_example/products/product.dart';
import 'package:playx_navigation_example/products/products_binding.dart';
import 'package:playx_navigation_example/products/products_page.dart';
import 'package:playx_navigation_example/splash/splash_binding.dart';
import 'package:playx_navigation_example/splash/splash_page.dart';

/// Router configuration that tests all PlayxBinding lifecycle scenarios:
///
/// 1. **Splash → Shell**: onEnter/onExit for standalone route.
/// 2. **Shell tab switching**: Home ↔ Products ↔ Explore → onHidden/onReEnter(false).
/// 3. **Parent → Child push**: Products → Product Details → onHidden/onReEnter(true).
/// 4. **Explore → Explore Details**: Same as #3 but in a different branch.
/// 5. **Cross-branch deep link**: From Explore → /products/:id. Products page mounts
///    as backstack (onEnter deferred), Details is top (onEnter fires immediately).
/// 6. **Direct deep link (web)**: Launch with /products/42 → same deferred behavior.
class AppPages {
  static final GoRouter router = GoRouter(
    initialLocation: Paths.splash,
    debugLogDiagnostics: true,
    routes: [
      // Standalone route: tests onEnter/onExit for a non-shell route.
      PlayxRoute(
        path: Paths.splash,
        name: Routes.splash,
        builder: (context, state) => const SplashPage(),
        binding: SplashBinding(),
      ),

      // Shell route with 3 tabs: Home, Products, Explore.
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => CupertinoPage(
          child: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs of the current tab: Explore > Featured #101.
                const SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: PlayxBreadcrumbs(
                      mode: PlayxBreadcrumbMode.shellBranch,
                    ),
                  ),
                ),
                Expanded(child: navigationShell),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Products',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore),
                  label: 'Explore',
                ),
              ],
            ),
          ),
        ),
        branches: [
          // Tab 1: Home (no children)
          PlayxShellBranch(
            name: Routes.home,
            path: Paths.home,
            breadcrumb: (context, state) => 'Home',
            builder: (context, state) => const HomePage(),
            binding: HomeBinding(),
          ),

          // Tab 2: Products → Product Details (parent-child push/pop)
          PlayxShellBranch(
            path: Paths.products,
            name: Routes.products,
            breadcrumb: (context, state) => 'Products',
            builder: (context, state) => const ProductsPage(),
            binding: ProductsBinding(),
            routes: [
              PlayxRoute(
                path: Paths.productDetails,
                name: Routes.productDetails,
                breadcrumb: (context, state) =>
                    state.extraAs<Product>()?.name ??
                    'Product #${state.pathParameters['id']}',
                builder: (context, state) =>
                    ProductDetailsPage(product: state.extra as Product?),
                binding: DetailsBinding(),
                loadingWidget: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),

          // Tab 3: Explore → Explore Details (parent-child push/pop)
          PlayxShellBranch(
            path: Paths.explore,
            name: Routes.explore,
            breadcrumb: (context, state) => 'Explore',
            builder: (context, state) => const ExplorePage(),
            binding: ExploreBinding(),
            routes: [
              // Route controller: no binding. The controller is created per
              // page, read with PlayxView, and disposed when the page exits.
              PlayxRoute<ExploreDetailsController>(
                path: Paths.exploreDetails,
                name: Routes.exploreDetails,
                // Until the product loads; the page then sets its name at
                // runtime with PlayxBreadcrumbLabel.
                breadcrumb: (context, state) =>
                    'Item #${state.pathParameters['id']}',
                controller: (context, state) => ExploreDetailsController(
                  id: state.intPathParam('id') ?? 0,
                  product: state.extraAs<Product>(),
                ),
                disposeController: (controller) => controller.dispose(),
                waitForBinding: false,
                builder: (context, state) => const ExploreDetailsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
