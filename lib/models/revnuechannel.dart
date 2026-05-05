class RevenueChannelModel {
  final String channel;
  final double revenue;

  RevenueChannelModel({
    required this.channel,
    required this.revenue,
  });

  factory RevenueChannelModel.fromJson(Map<String, dynamic> json) {
    return RevenueChannelModel(
      channel: json['channel'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}