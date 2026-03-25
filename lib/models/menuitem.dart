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
    // Category can be a string or nested { name: "..." }
    String category = 'Other';
    final catRaw = j['category'] ?? j['categoryName'];
    if (catRaw is Map)
      category = (catRaw['name'] ?? 'Other').toString();
    else if (catRaw != null) category = catRaw.toString();

    // Price from various field names
    final price = double.tryParse(
            (j['price'] ?? j['basePrice'] ?? j['unitPrice'] ?? 0).toString()) ??
        0;

    return MenuItem(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      category: category,
      price: price,
      description: (j['description'] ?? j['subtitle'] ?? '').toString(),
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
