import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:savorya_staff/models/analytics.dart';
import 'package:savorya_staff/models/restuarent.dart';
import 'package:savorya_staff/models/retention.dart';
import 'package:savorya_staff/models/revnuechannel.dart';
import 'package:savorya_staff/screens/Analytics%20Screen/analytics_detail_screen.dart';
import 'package:savorya_staff/services/apiservice.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<RestaurantModel> restaurants = [];
  RestaurantModel? selectedRestaurant;

  bool isLoading = true;
  bool isAnalyticsLoading = false;
  RetentionModel? retention;
  bool isRetentionLoading = false;

  AnalyticsModel? analytics;
  List<RevenueChannelModel> revenueChannels = [];
  bool isRevenueLoading = false;

  static const _blue = Color(0xFF2563EB);
  static const _dark = Color(0xFF111827);
  static const _grey = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    final res = await ApiService.getRestaurants();

    if (!mounted) return;

    if (res.ok && res.data != null) {
      restaurants = res.data!;
      selectedRestaurant =
          restaurants.isNotEmpty ? restaurants.first : null;

      setState(() => isLoading = false);

      if (selectedRestaurant != null) {
        _fetchAnalytics(selectedRestaurant!.id);
        _fetchRetention(selectedRestaurant!.id);
        _fetchRevenue(selectedRestaurant!.id);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAnalytics(String rId) async {
    setState(() => isAnalyticsLoading = true);

    final res = await ApiService.getAovAnalytics(rId);

    if (!mounted) return;

    if (res.ok && res.data != null) {
      setState(() {
        analytics = res.data;
        isAnalyticsLoading = false;
      });
    } else {
      setState(() => isAnalyticsLoading = false);
    }
  }

  Future<void> _fetchRetention(String rId) async {
    setState(() => isRetentionLoading = true);

    final res = await ApiService.getCustomerRetention(rId);

    if (!mounted) return;

    if (res.ok && res.data != null) {
      setState(() {
        retention = res.data;
        isRetentionLoading = false;
      });
    } else {
      setState(() => isRetentionLoading = false);
    }
  }

  Future<void> _fetchRevenue(String rId) async {
    setState(() => isRevenueLoading = true);

    final res = await ApiService.getRevenueByChannel(rId);

    if (!mounted) return;

    if (res.ok && res.data != null) {
      setState(() {
        revenueChannels = res.data!;
        isRevenueLoading = false;
      });
    } else {
      setState(() => isRevenueLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _dropdown(),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Analytics",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  selectedRestaurant?.name ?? "Loading...",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.notifications_none, color: Colors.white)
        ],
      ),
    );
  }

  Widget _dropdown() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }

    if (restaurants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No restaurants found"),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<RestaurantModel>(
            value: selectedRestaurant,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: restaurants.map((r) {
              return DropdownMenuItem(
                value: r,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          (r.logo != null && r.logo!.isNotEmpty)
                              ? NetworkImage(r.logo!)
                              : null,
                      child: (r.logo == null || r.logo!.isEmpty)
                          ? const Icon(Icons.store, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: _dark),
                          ),
                          Text(
                            r.city ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: _grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;

              setState(() {
                selectedRestaurant = val;
              });

              _fetchAnalytics(val.id);
              _fetchRetention(val.id);
              _fetchRevenue(val.id);
            },
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (selectedRestaurant == null) {
      return const Center(child: Text("No restaurant selected"));
    }

    if (isAnalyticsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Overview",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _dark)),

          const SizedBox(height: 12),

          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _StatCard("₹${analytics?.totalRevenue ?? 0}", "Revenue", Colors.green),
                _StatCard("${analytics?.totalOrders ?? 0}", "Orders", Colors.blue),
                _StatCard("₹${analytics?.avgOrderValue?.toStringAsFixed(0) ?? 0}", "Avg Order", Colors.orange),
                _StatCard("${retention?.retentionRate ?? 0}%", "Retention", Colors.purple),
                _StatCard("${retention?.totalCustomers ?? 0}", "Customers", Colors.brown),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text("Insights",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _dark)),

          const SizedBox(height: 12),

         _revenueInsight(),
          _insightCard("Peak Kitchen Hours"),
          _insightCard("Item Preparation Time"),
          _insightCard("Customer Retention"),
        ],
      ),
    );
  }


Widget _insightCard(String title, {String? type}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalyticsDetailScreen(
            type: type ?? title,
            revenueChannels: revenueChannels,
            analytics: analytics,
            retention: retention,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.show_chart, color: _blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _dark)),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14)
        ],
      ),
    ),
  );
}
Widget _revenueInsight() {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalyticsDetailScreen(
            type: "revenue",
            revenueChannels: revenueChannels,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bar_chart, color: _blue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text("Revenue by Channel",
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: _dark)),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14)
        ],
      ),
    ),
  );
}

}

class _StatCard extends StatelessWidget {
  final String value;
  final String title;
  final Color color;

  const _StatCard(this.value, this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.circle, size: 10, color: color),
          ),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827))),
          Text(title,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
  
}
