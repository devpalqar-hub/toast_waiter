import 'package:flutter/material.dart';

class UserIdField extends StatelessWidget {
  final TextEditingController controller;

  const UserIdField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,

      decoration: InputDecoration(
        hintText: "User ID",

        filled: true,
        fillColor: Colors.grey.shade100,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),

        suffixIcon: const Icon(Icons.badge),
      ),
    );
  }
}
