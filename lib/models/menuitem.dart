class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final double? effectivePrice; // ✅ nullable
  final String description;
  final String? imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.effectivePrice, 
    required this.description,
    this.imageUrl,
  });

  /// ✅ Show effectivePrice only if it exists and > 0
  double get displayPrice =>
      (effectivePrice != null && effectivePrice! > 0)
          ? effectivePrice!
          : price;

  factory MenuItem.fromJson(Map<String, dynamic> j) {
    // ✅ Category parsing
    String category = 'Other';
    final catRaw = j['category'] ?? j['categoryName'];
    if (catRaw is Map) {
      category = (catRaw['name'] ?? 'Other').toString();
    } else if (catRaw != null) {
      category = catRaw.toString();
    }

    // ✅ Base price
    final basePrice = double.tryParse(
          (j['price'] ?? j['basePrice'] ?? j['unitPrice'] ?? 0).toString(),
        ) ??
        0;

    // ✅ Nullable effective price
    final effectivePrice = double.tryParse(
      (j['effectivePrice'] ?? j['currentPrice'] ?? j['finalPrice'] ?? '')
          .toString(),
    );

    return MenuItem(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      category: category,
      price: basePrice,
      effectivePrice: effectivePrice, // ✅ keep nullable
      description: (j['description'] ?? j['subtitle'] ?? '').toString(),
      imageUrl: (j['imageUrl'] ?? j['image'] ?? j['photo'])?.toString(),
    );
  }
}

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem(this.item, {this.quantity = 1});

  double get subtotal => item.displayPrice * quantity;
}


