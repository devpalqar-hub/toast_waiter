import 'package:flutter/material.dart';
import 'package:savorya_staff/models/analytics.dart';
import 'package:savorya_staff/models/retention.dart';
import 'package:savorya_staff/models/revnuechannel.dart';

class AnalyticsDetailScreen extends StatelessWidget {
  final String type;
  final List<RevenueChannelModel>? revenueChannels;
  final AnalyticsModel? analytics;
  final RetentionModel? retention;

  const AnalyticsDetailScreen({
    super.key,
    required this.type,
    this.revenueChannels,
    this.analytics,
    this.retention,
  });

  static const _dark = Color(0xFF111827);
  static const _grey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(),
            style: const TextStyle(color: _dark)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContent(),
      ),
    );
  }

  /// 🔥 TITLE BASED ON TYPE
  String _getTitle() {
    switch (type) {
      case "revenue":
        return "Revenue by Channel";
      case "peak":
        return "Peak Kitchen Hours";
      case "prep":
        return "Item Preparation";
      case "retention":
        return "Customer Retention";
      default:
        return "Analytics Details";
    }
  }

  /// 🔥 MAIN CONTENT SWITCH
  Widget _buildContent() {
    switch (type) {
      case "revenue":
        return _revenueView();
      case "retention":
        return _retentionView();
      case "peak":
        return _simpleView("8PM - 10PM", "Peak Hours");
      case "prep":
        return _simpleView("25 mins", "Avg Prep Time");
      default:
        return const Center(child: Text("No Data"));
    }
  }

  /// 🔹 REVENUE VIEW
  Widget _revenueView() {
    if (revenueChannels == null || revenueChannels!.isEmpty) {
      return const Center(child: Text("No revenue data"));
    }

    return Column(
      children: revenueChannels!.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.channel, style: const TextStyle(color: _grey)),
              Text("₹${e.revenue.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _dark)),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 🔹 RETENTION VIEW
  Widget _retentionView() {
    if (retention == null) {
      return const Center(child: Text("No retention data"));
    }

    return Column(
      children: [
        _infoTile("Total Customers", "${retention!.totalCustomers}"),
        _infoTile("Returning", "${retention!.returningCustomers}"),
        _infoTile("Churned", "${retention!.churnedCustomers}"),
        _infoTile("Retention Rate", "${retention!.retentionRate}%"),
      ],
    );
  }

  /// 🔹 SIMPLE VIEW (TEMP DATA)
  Widget _simpleView(String value, String label) {
    return Column(
      children: [
        _bigCard(value),
        const SizedBox(height: 20),
        _infoTile(label, value),
      ],
    );
  }

  /// 🔹 BIG DISPLAY CARD
  Widget _bigCard(String value) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        value,
        style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _dark),
      ),
    );
  }

  /// 🔹 INFO TILE
  Widget _infoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: _grey)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _dark)),
        ],
      ),
    );
  }
}