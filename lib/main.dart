import 'package:flutter/material.dart';
import 'waiter/waiter_login/waiter_Login_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WaiterLoginScreen(),
    );
  }
}
