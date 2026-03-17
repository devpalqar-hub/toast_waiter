import 'package:flutter/material.dart';
import '../models/tablemodel.dart';

class TableCard extends StatelessWidget {
  final TableModel table;

  const TableCard({super.key, required this.table});

  Color getColor() {
    switch (table.status) {
      case "occupied":
        return Colors.red.shade200;

      case "reserved":
        return Colors.orange.shade200;

      default:
        return Colors.green.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                table.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                "${table.seats} Seats",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),

            decoration: BoxDecoration(
              color: getColor(),
              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              table.status,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
