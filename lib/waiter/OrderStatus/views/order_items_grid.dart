import 'package:flutter/material.dart';
import 'order_item_card.dart';

class OrderItemsGrid extends StatelessWidget {
  const OrderItemsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: const [
        OrderItemCard("ADD", ""),
        OrderItemCard("Margherita Pizza", "READY"),
        OrderItemCard("Truffle Fries", "PREPARING"),
        OrderItemCard("Classic Lasagna", "PLACED"),
        OrderItemCard("Diet Coke", "SERVED"),
        OrderItemCard("Garlic Bread", "UNAVAILABLE"),
      ],
    );
  }
}
