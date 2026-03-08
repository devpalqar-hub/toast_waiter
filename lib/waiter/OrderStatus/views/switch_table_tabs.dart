import 'package:flutter/material.dart';

class SwitchTableTabs extends StatelessWidget {
  const SwitchTableTabs({super.key});

  Widget table(String name, bool active) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: active ? Colors.blue : Colors.grey.shade300),
      ),
      child: Text(name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          table("T3", true),
          table("T4", false),
          table("T5", false),
          table("T6", false),
          table("T7", false),
          table("T8", false),
        ],
      ),
    );
  }
}
