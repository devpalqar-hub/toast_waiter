import 'package:flutter/material.dart';
import 'package:toast_waiter/services/auth_service.dart';

class SendOtpButton extends StatelessWidget {
  final TextEditingController emailController;

  const SendOtpButton({super.key, required this.emailController});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        bool success = await AuthService.sendOtp(emailController.text);

        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("OTP Sent to Email")));
        }
      },

      child: const Text("Send OTP"),
    );
  }
}
