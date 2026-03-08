import 'package:flutter/material.dart';
import 'views/order_header.dart';
import 'views/switch_table_tabs.dart';
import 'views/order_reference_card.dart';
import 'views/order_items_grid.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      body: SafeArea(
        child: Column(
          children: const [
            SizedBox(height: 15),

            OrderHeader(),

            SizedBox(height: 20),

            SwitchTableTabs(),

            SizedBox(height: 20),

            OrderReferenceCard(),

            SizedBox(height: 20),

            Expanded(child: OrderItemsGrid()),
          ],
        ),
      ),
    );
  }
}
