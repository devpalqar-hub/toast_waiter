import 'package:flutter/material.dart';

class OrderReferenceCard extends StatelessWidget {
  const OrderReferenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ORDER REFERENCE",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "#ORD-1204",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "TOTAL AMOUNT",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "\$54.50",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey),

              SizedBox(width: 5),

              Text("12:45 PM"),

              SizedBox(width: 15),

              Icon(Icons.people, size: 16, color: Colors.grey),

              SizedBox(width: 5),

              Text("4 Seat"),
            ],
          ),
        ],
      ),
    );
  }
}
