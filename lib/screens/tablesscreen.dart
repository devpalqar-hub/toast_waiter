import 'package:flutter/material.dart';
import '../models/tablemodel.dart';
import '../services/apiservice.dart';
import '../widgets/tablecard.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  List<TableModel> tables = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTables();
  }

  void loadTables() async {
    final response = await ApiService.getTables(
      "69e2b73a-875c-470b-805b-2ff148897790", // your restaurant id
      "YOUR_TOKEN_HERE",
    );

    print("Tables API response: $response");

    setState(() {
      tables = response;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tables")),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),

              child: GridView.builder(
                itemCount: tables.length,

                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),

                itemBuilder: (context, index) {
                  final table = tables[index];

                  return TableCard(table: table);
                },
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
