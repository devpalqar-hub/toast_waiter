class TableModel {
  final String id;
  final String name; // just the number/label e.g. "1", "2", "A1"
  final String status;
  final int seats;
  final List<String> items;

  TableModel({
    required this.id,
    required this.name,
    required this.status,
    required this.seats,
    required this.items,
  });

  factory TableModel.fromJson(Map<String, dynamic> j) {
    final raw = (j['status'] ?? 'available').toString().toLowerCase();
    String status;
    if (raw == 'occupied' || raw.contains('occup') || raw == 'busy') {
      status = 'occupied';
    } else if (raw == 'reserved' || raw.contains('reserv') || raw == 'booked') {
      status = 'reserved';
    } else {
      status = 'available';
    }

    List<String> items = [];
    final rawItems = j['items'] ?? j['currentItems'] ?? [];
    if (rawItems is List) {
      items = rawItems
          .map((e) => e is Map ? (e['name'] ?? '').toString() : e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Get raw name from any field the API might use
    String rawName =
        (j['name'] ?? j['tableNumber'] ?? j['number'] ?? j['label'] ?? '')
            .toString()
            .trim();

    // Remove leading "Table " or "table " prefix if present
    // so "Table 1" becomes "1", "Table A" becomes "A"
    if (rawName.toLowerCase().startsWith('table ')) {
      rawName = rawName.substring(6).trim();
    }
    if (rawName.isEmpty) rawName = '?';

    return TableModel(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      name: rawName,
      status: status,
      seats: int.tryParse((j['seatCount'] ?? j['seats'] ?? j['capacity'] ?? 2)
              .toString()) ??
          2,
      items: items,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
}
