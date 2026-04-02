abstract class Routes {
  static const splash = 'splash';
  static const home = 'home';
  static const products = 'products';
  static const productDetails = 'productDetails';
  static const explore = 'explore';
  static const exploreDetails = 'exploreDetails';
}

abstract class Paths {
  static const splash = '/splash';
  static const home = '/home';
  static const products = '/products';
  static const productDetails = ':id';
  static const explore = '/explore';
  static const exploreDetails = ':id';
}
