class AnalyticsModel {
  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;

  AnalyticsModel({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      avgOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
    );
  }
}