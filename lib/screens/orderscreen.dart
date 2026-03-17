import 'package:flutter/material.dart';

class OrderScreen extends StatelessWidget {
  final String tableId;

  const OrderScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Table $tableId Orders")),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: const [
          ListTile(
            title: Text("Margherita Pizza"),
            subtitle: Text("READY"),
            trailing: Text("1x"),
          ),

          ListTile(
            title: Text("Truffle Fries"),
            subtitle: Text("PREPARING"),
            trailing: Text("2x"),
          ),
        ],
      ),
    );
  }
}
