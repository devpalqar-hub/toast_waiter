// Session = active order for a table
// A session has multiple batches, each batch has items
class OrderModel {
  final String id; // sessionId
  final String reference;
  final String tableId;
  final String createdAt;
  final double total;
  final int seats;
  final String status;
  final List<OrderItem> items; // flattened from all batches

  OrderModel({
    required this.id,
    required this.reference,
    required this.tableId,
    required this.createdAt,
    required this.total,
    required this.seats,
    required this.status,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['sessionId'] ?? '').toString();

    // Flatten items from batches
    final List<OrderItem> items = [];
    final batches = j['batches'] ?? j['orderBatches'] ?? [];
    if (batches is List) {
      for (final batch in batches) {
        if (batch is! Map) continue;
        final batchId = (batch['id'] ?? '').toString();
        final batchItems = batch['items'] ?? batch['orderItems'] ?? [];
        if (batchItems is List) {
          for (final item in batchItems) {
            if (item is Map<String, dynamic>) {
              items.add(OrderItem.fromJson(item, batchId: batchId));
            }
          }
        }
      }
    }

    // Also try direct items array (some APIs flatten it)
    final directItems = j['items'] ?? [];
    if (directItems is List && items.isEmpty) {
      for (final item in directItems) {
        if (item is Map<String, dynamic>) {
          items.add(OrderItem.fromJson(item));
        }
      }
    }

    // Total from bill or direct
    double total = 0;
    final bill = j['bill'] ?? j['currentBill'] ?? {};
    if (bill is Map) {
      total = double.tryParse(
              (bill['total'] ?? bill['totalAmount'] ?? 0).toString()) ??
          0;
    }
    if (total == 0) {
      total =
          double.tryParse((j['total'] ?? j['totalAmount'] ?? 0).toString()) ??
              0;
    }

    final tableId = (j['tableId'] ?? j['table']?['id'] ?? '').toString();
    final ref = j['sessionNumber']?.toString() ??
        j['orderNumber']?.toString() ??
        '#ORD-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id}';

    return OrderModel(
      id: id,
      reference: ref,
      tableId: tableId,
      createdAt:
          (j['createdAt'] ?? j['openedAt'] ?? j['startedAt'] ?? '').toString(),
      total: total,
      seats: int.tryParse(
              (j['guestCount'] ?? j['seats'] ?? j['covers'] ?? 1).toString()) ??
          1,
      status: (j['status'] ?? 'OPEN').toString(),
      items: items,
    );
  }
}

class OrderItem {
  final String id;
  final String batchId;
  final String name;
  final String status;
  final String notes;
  final int quantity;

  OrderItem({
    required this.id,
    required this.batchId,
    required this.name,
    required this.status,
    required this.notes,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j, {String batchId = ''}) {
    // Name from item or nested menuItem
    final name = (j['name'] ??
            j['itemName'] ??
            j['menuItem']?['name'] ??
            j['menuItemName'] ??
            'Item')
        .toString();

    return OrderItem(
      id: (j['id'] ?? '').toString(),
      batchId: batchId,
      name: name,
      status: (j['status'] ?? 'PLACED').toString().toUpperCase(),
      notes: (j['notes'] ?? j['specialInstructions'] ?? '').toString(),
      quantity: int.tryParse((j['quantity'] ?? j['qty'] ?? 1).toString()) ?? 1,
    );
  }
}
