import 'package:flutter/material.dart';
import 'screens/loginscreen.dart';

void main() {
  runApp(const ToastWaiter());
}

class ToastWaiter extends StatelessWidget {
  const ToastWaiter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Toast Waiter',

      theme: ThemeData(primarySwatch: Colors.blue),

      home: const LoginScreen(),
    );
  }
}
