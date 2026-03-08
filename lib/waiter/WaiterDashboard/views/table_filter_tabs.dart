import 'package:flutter/material.dart';

class TableFilterTabs extends StatelessWidget {
  const TableFilterTabs({super.key});

  Widget chip(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3B82F6) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: active ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          chip("All Tables", true),

          const SizedBox(width: 10),

          chip("Available (5)", false),

          const SizedBox(width: 10),

          chip("Occupied (2)", false),
        ],
      ),
    );
  }
}
