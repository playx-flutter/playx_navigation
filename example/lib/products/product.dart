class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;

  Product(
      {required this.id,
      required this.name,
      required this.description,
      required this.price,
      this.imageUrl});
}
