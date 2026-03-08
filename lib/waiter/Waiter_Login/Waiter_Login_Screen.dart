import 'package:flutter/material.dart';
import 'views/login_header.dart';
import 'views/user_id_field.dart';
import 'views/otp_field.dart';
import 'views/login_button.dart';
import 'views/send_otp_button.dart';

class WaiterLoginScreen extends StatefulWidget {
  const WaiterLoginScreen({super.key});

  @override
  State<WaiterLoginScreen> createState() => _WaiterLoginScreenState();
}

class _WaiterLoginScreenState extends State<WaiterLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff1f5f9), Color(0xffdbeafe)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 25),

              padding: const EdgeInsets.all(28),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),

                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(.15),
                    blurRadius: 40,
                    spreadRadius: 5,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoginHeader(),

                  const SizedBox(height: 25),

                  const Text(
                    "Staff Login",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1e293b),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Enter your credentials to start shift",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),

                  const SizedBox(height: 30),

                  /// USER ID
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Employee ID",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  UserIdField(controller: emailController),

                  const SizedBox(height: 20),

                  /// OTP
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "OTP",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  OtpField(controller: otpController),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(value: false, onChanged: (v) {}),
                          const Text("Remember Me"),
                        ],
                      ),

                      const Text(
                        "Forgot Pin",
                        style: TextStyle(
                          color: Color(0xff3b82f6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  LoginButton(
                    emailController: emailController,
                    otpController: otpController,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
