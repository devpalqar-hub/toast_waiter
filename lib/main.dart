import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/loginscreen.dart';
import 'screens/tablesscreen.dart';
import 'services/apiservice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Check if already logged in
  final token = await ApiService.getToken();
  final rId = await ApiService.getRestaurantId();
  runApp(SavoryaApp(isLoggedIn: token != null && rId != null));
}

class SavoryaApp extends StatelessWidget {
  final bool isLoggedIn;
  const SavoryaApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savorya Staff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const TablesScreen() : const LoginScreen(),
    );
  }
}
