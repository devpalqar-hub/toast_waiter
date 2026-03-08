import 'dart:convert';
import 'package:http/http.dart' as http;
import 'table_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "https://api.pos.palqar.cloud/api/v1";

  /// SEND OTP
  static Future<bool> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  /// VERIFY OTP
  static Future<String?> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["data"]["accessToken"];
    } else {
      return null;
    }
  }

  static Future<List<TableModel>> getTables(String restaurantId) async {
   final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/restaurants/$restaurantId/tables"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    List tables = data["data"];

    return tables.map((e) => TableModel.fromJson(e)).toList();
  }
}

