import 'package:flutter/material.dart';
import '../services/apiservice.dart';
import 'tablesscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController employeeController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool loading = false;

  void login() {
    if (employeeController.text.isEmpty || otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Employee ID and OTP")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TableScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffeef2ff), Color(0xfff8fafc)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(30),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Logo + Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff6366f1), Color(0xff3b82f6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Text(
                        "Savorya ",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1e293b),
                        ),
                      ),

                      const Text(
                        "Staff",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff3b82f6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Staff Login",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0f172a),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Enter your credentials to start shift",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  const SizedBox(height: 30),

                  /// Employee ID
                  const Text(
                    "Employee ID",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: employeeController,

                    decoration: InputDecoration(
                      hintText: "User ID",

                      prefixIcon: const Icon(Icons.person_outline),

                      suffixIcon: const Icon(Icons.badge_outlined),

                      filled: true,
                      fillColor: const Color(0xfff8fafc),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// OTP
                  const Text(
                    "OTP",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,

                    decoration: InputDecoration(
                      hintText: "Enter OTP",

                      prefixIcon: const Icon(Icons.lock_outline),

                      suffixText: "0/6",

                      filled: true,
                      fillColor: const Color(0xfff8fafc),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// Forgot Pin
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot Pin →",
                        style: TextStyle(
                          color: Color(0xff3b82f6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton(
                      onPressed: loading ? null : login,

                      style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: const Color(0xff4f46e5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),

                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Login & Start Shift",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                            ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
