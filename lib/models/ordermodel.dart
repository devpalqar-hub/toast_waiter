
class SessionModel {
  final String id;
  final String sessionNumber;
  final String status;
  final String tableId;
  final String tableName;
  final String createdAt;
  final double totalAmount;
  final int batchCount;
  final int guestCount;

  SessionModel({
    required this.id,
    required this.sessionNumber,
    required this.status,
    required this.tableId,
    required this.tableName,
    required this.createdAt,
    required this.totalAmount,
    required this.batchCount,
    required this.guestCount,
  });

  factory SessionModel.fromJson(Map<String, dynamic> j) {
    final table = j['table'] is Map ? j['table'] as Map : {};
    return SessionModel(
      id: (j['id'] ?? '').toString(),
      sessionNumber: (j['sessionNumber'] ?? '').toString(),
      status: (j['status'] ?? 'OPEN').toString().toUpperCase(),
      tableId: (j['tableId'] ?? table['id'] ?? '').toString(),
      tableName: (table['name'] ?? '').toString(),
      createdAt: (j['createdAt'] ?? '').toString(),
      totalAmount: double.tryParse((j['totalAmount'] ?? 0).toString()) ?? 0,
      batchCount: int.tryParse(
              ((j['_count'] is Map ? j['_count']['batches'] : null) ?? 0)
                  .toString()) ??
          0,
      guestCount: int.tryParse((j['guestCount'] ?? 1).toString()) ?? 1,
    );
  }

  bool get isOpen => status == 'OPEN';
  bool get isBilled => status == 'BILLED';
}


class OrderModel {
  final String id;
  final String sessionNumber;
  final String status;
  final String tableId;
  final String tableName;
  final String createdAt;
  final double totalAmount;
  final double subtotal;
  final double taxAmount;
  final int guestCount;
  final String? customerName;
  final List<BatchModel> batches;

  OrderModel({
    required this.id,
    required this.sessionNumber,
    required this.status,
    required this.tableId,
    required this.tableName,
    required this.createdAt,
    required this.totalAmount,
    required this.subtotal,
    required this.taxAmount,
    required this.guestCount,
    this.customerName,
    required this.batches,
  });

 
  double get calculatedTotal {
    if (totalAmount > 0) return totalAmount;
    return batches
        .expand((b) => b.items)
        .fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final table = j['table'] is Map ? j['table'] as Map : {};
    final batchList = j['batches'] is List ? j['batches'] as List : [];
    return OrderModel(
      id: (j['id'] ?? '').toString(),
      sessionNumber: (j['sessionNumber'] ?? '').toString(),
      status: (j['status'] ?? 'OPEN').toString().toUpperCase(),
      tableId: (j['tableId'] ?? table['id'] ?? '').toString(),
      tableName: (table['name'] ?? '').toString(),
      createdAt: (j['createdAt'] ?? '').toString(),
      totalAmount: double.tryParse((j['totalAmount'] ?? 0).toString()) ?? 0,
      subtotal: double.tryParse((j['subtotal'] ?? 0).toString()) ?? 0,
      taxAmount: double.tryParse((j['taxAmount'] ?? 0).toString()) ?? 0,
      guestCount: int.tryParse((j['guestCount'] ?? 1).toString()) ?? 1,
      customerName: j['customerName']?.toString(),
      batches: batchList
          .whereType<Map<String, dynamic>>()
          .map(BatchModel.fromJson)
          .toList(),
    );
  }
}


class BatchModel {
  final String id;
  final String batchNumber;
  final String status;
  final String createdAt;
  final List<OrderItem> items;

  BatchModel({
    required this.id,
    required this.batchNumber,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory BatchModel.fromJson(Map<String, dynamic> j) {
    final itemList = j['items'] is List ? j['items'] as List : [];
    return BatchModel(
      id: (j['id'] ?? '').toString(),
      batchNumber: (j['batchNumber'] ?? '').toString(),
      status: (j['status'] ?? 'PENDING').toString().toUpperCase(),
      createdAt: (j['createdAt'] ?? '').toString(),
      items: itemList
          .whereType<Map<String, dynamic>>()
          .map(
              (i) => OrderItem.fromJson(i, batchId: (j['id'] ?? '').toString()))
          .toList(),
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
  final double unitPrice;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.batchId,
    required this.name,
    required this.status,
    required this.notes,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j, {String batchId = ''}) {
    final menuItem = j['menuItem'] is Map ? j['menuItem'] as Map : {};
    final name = (j['name'] ?? menuItem['name'] ?? 'Item').toString();
    return OrderItem(
      id: (j['id'] ?? '').toString(),
      batchId: batchId.isNotEmpty ? batchId : (j['batchId'] ?? '').toString(),
      name: name,
      status: (j['status'] ?? 'PENDING').toString().toUpperCase(),
      notes: (j['notes'] ?? '').toString(),
      quantity: int.tryParse((j['quantity'] ?? 1).toString()) ?? 1,
      unitPrice: double.tryParse((j['unitPrice'] ?? 0).toString()) ?? 0,
      imageUrl: (menuItem['imageUrl'] ?? j['imageUrl'])?.toString(),
    );
  }
}
