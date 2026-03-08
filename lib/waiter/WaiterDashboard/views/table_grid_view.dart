import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/table_model.dart';
import 'table_card.dart';

class TableGridView extends StatelessWidget {
  const TableGridView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TableModel>>(
      future: AuthService.getTables("YOUR_RESTAURANT_ID"),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading tables"));
        }

        final tables = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          itemCount: tables.length,

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),

          itemBuilder: (context, index) {
            final table = tables[index];

            return TableCard(tableName: table.name, seats: table.seatCount);
          },
        );
      },
    );
  }
}
