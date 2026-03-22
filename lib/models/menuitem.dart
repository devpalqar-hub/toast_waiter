class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String? imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) {
    // Category from nested object or string
    String category = 'Other';
    final cat = j['category'] ?? j['categoryName'];
    if (cat is Map) {
      category = (cat['name'] ?? 'Other').toString();
    } else if (cat != null) {
      category = cat.toString();
    }

    return MenuItem(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      category: category,
      price:
          double.tryParse((j['price'] ?? j['basePrice'] ?? 0).toString()) ?? 0,
      description: (j['description'] ?? '').toString(),
      imageUrl: (j['imageUrl'] ?? j['image'] ?? j['photo'])?.toString(),
    );
  }
}

class CartItem {
  final MenuItem item;
  int quantity;
  CartItem(this.item, {this.quantity = 1});
  double get subtotal => item.price * quantity;
}
