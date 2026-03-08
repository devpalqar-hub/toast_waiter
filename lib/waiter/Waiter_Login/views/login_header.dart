import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.restaurant,
            color: Color(0xFF3B82F6),
            size: 20,
          ),
        ),

        const SizedBox(width: 10),

        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: "Savorya ",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              TextSpan(
                text: "Staff",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
