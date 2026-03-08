import 'package:flutter/material.dart';

class OrderItemCard extends StatelessWidget {
  final String name;
  final String status;

  const OrderItemCard(this.name, this.status, {super.key});

  Color statusColor() {
    switch (status) {
      case "READY":
        return Colors.green;
      case "PREPARING":
        return Colors.orange;
      case "PLACED":
        return Colors.blue;
      case "SERVED":
        return Colors.grey;
      case "UNAVAILABLE":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color statusBg() {
    return statusColor().withOpacity(0.15);
  }

  @override
  Widget build(BuildContext context) {
    /// ADD ITEMS CARD
    if (name == "ADD") {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.shade200,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
            ),

            SizedBox(height: 10),

            Text(
              "ADD ITEMS",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    /// NORMAL FOOD CARD
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Quantity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "1x",
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),

          const SizedBox(height: 10),

          /// Food Name
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),

          const Spacer(),

          /// Status Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusBg(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor(),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
