import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/loginscreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SavoryaApp());
}

class SavoryaApp extends StatelessWidget {
  const SavoryaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savorya Staff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
