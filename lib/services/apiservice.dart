import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tablemodel.dart';

class ApiService {
  static const String baseUrl = "https://api.pos.palqar.cloud/api/v1";

  static Future<List<TableModel>> getTables(
    String restaurantId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/restaurants/$restaurantId/tables"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => TableModel.fromJson(e)).toList();
    }

    return [];
  }
}
