class RetentionModel {
  final int totalCustomers;
  final int returningCustomers;
  final double retentionRate;
  final int churnedCustomers;

  RetentionModel({
    required this.totalCustomers,
    required this.returningCustomers,
    required this.retentionRate,
    required this.churnedCustomers,
  });

  factory RetentionModel.fromJson(Map<String, dynamic> json) {
    return RetentionModel(
      totalCustomers: json['totalCustomers'] ?? 0,
      returningCustomers: json['returningCustomers'] ?? 0,
      retentionRate: (json['retentionRate'] ?? 0).toDouble(),
      churnedCustomers: json['churnedCustomers'] ?? 0,
    );
  }
}