class TableModel {
  final String id;
  final String name;
  final int seats;
  final String status;

  TableModel({
    required this.id,
    required this.name,
    required this.seats,
    required this.status,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json["id"].toString(),
      name: json["name"] ?? "",
      seats: json["seats"] ?? 0,
      status: json["status"] ?? "available",
    );
  }
}
