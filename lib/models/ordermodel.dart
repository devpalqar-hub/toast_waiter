class OrderModel {
  final String itemName;
  final int quantity;
  final String status;

  OrderModel({
    required this.itemName,
    required this.quantity,
    required this.status,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      itemName: json['name'] ?? "",
      quantity: json['qty'] ?? 0,
      status: json['status'] ?? "",
    );
  }
}
