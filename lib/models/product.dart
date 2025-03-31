class Product {
  final String image;
  final String name;
  final int price;

  Product({
    required this.image,
    required this.name,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      image: json['image'],
      name: json['name'],
      price: json['price'],
    );
  }
}
