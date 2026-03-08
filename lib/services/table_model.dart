class TableModel {
  final String id;
  final String name;
  final int seatCount;

  TableModel({required this.id, required this.name, required this.seatCount});

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json["id"],
      name: json["name"],
      seatCount: json["seatCount"] ?? 0,
    );
  }
}
