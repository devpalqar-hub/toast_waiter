import 'package:flutter/material.dart';
import 'views/dashboard_header.dart';
import 'views/table_filter_tabs.dart';
import 'views/table_grid_view.dart';

class WaiterDashboardScreen extends StatelessWidget {
  const WaiterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () {},
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: Column(
          children: const [
            SizedBox(height: 20),

            DashboardHeader(),

            SizedBox(height: 20),

            TableFilterTabs(),

            SizedBox(height: 20),

            Expanded(child: TableGridView()),
          ],
        ),
      ),
    );
  }
}
