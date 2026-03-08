import 'package:flutter/material.dart';
import 'package:toast_waiter/services/auth_service.dart';
import '../../WaiterDashboard/waiter_dashboard_screen.dart';

class LoginButton extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController otpController;

  const LoginButton({
    super.key,
    required this.emailController,
    required this.otpController,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        print("EMAIL: ${emailController.text}");
        print("OTP: ${otpController.text}");

        String? token = await AuthService.verifyOtp(
          emailController.text,
          otpController.text,
        );

        print("TOKEN RESPONSE: $token");

        if (token != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WaiterDashboardScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
        }
      },

      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),

      child: const Text("Login & Start Shift", style: TextStyle(fontSize: 16)),
    );
  }
}
