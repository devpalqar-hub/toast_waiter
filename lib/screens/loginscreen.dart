import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/apiservice.dart';
import 'tablesscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpStep = false;
  bool _isLoading = false;
  String _error = '';

  late final AnimationController _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 350), vsync: this)
    ..forward();
  late final AnimationController _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 400), vsync: this);

  static const _blue = Color(0xFF2563EB);
  static const _dark = Color(0xFF111827);
  static const _grey = Color(0xFF6B7280);
  static const _red = Color(0xFFEF4444);
  static const _border = Color(0xFFE5E7EB);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _fadeCtrl.dispose();
    _shakeCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpNodes) f.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your User ID');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final res = await ApiService.sendOtp(_emailCtrl.text.trim());
    setState(() => _isLoading = false);

    if (res.ok) {
      setState(() => _isOtpStep = true);
      _fadeCtrl.reset();
      _fadeCtrl.forward();
      Future.delayed(
          const Duration(milliseconds: 200), () => _otpNodes[0].requestFocus());
    } else {
      setState(() => _error = res.error ?? 'Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _error = 'Enter the complete 6-digit code');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final res = await ApiService.verifyOtp(_emailCtrl.text.trim(), otp);
    setState(() => _isLoading = false);

    if (res.ok) {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const TablesScreen()));
    } else {
      setState(() => _error = res.error ?? 'Invalid OTP');
      _shakeCtrl.forward(from: 0);
      for (final c in _otpCtrls) c.clear();
      _otpNodes[0].requestFocus();
    }
  }

  void _goBack() {
    setState(() {
      _isOtpStep = false;
      _error = '';
    });
    for (final c in _otpCtrls) c.clear();
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  void _otpChanged(String val, int i) {
    setState(() => _error = '');
    if (val.isNotEmpty && i < 5) _otpNodes[i + 1].requestFocus();
    if (val.isEmpty && i > 0) _otpNodes[i - 1].requestFocus();
    if (i == 5 && val.isNotEmpty) _verifyOtp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 60),
              _buildLogo(),
              const SizedBox(height: 48),
              _buildStepBar(),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _shakeCtrl,
                builder: (_, child) {
                  final dx = _shakeCtrl.isAnimating
                      ? ((_shakeCtrl.value * 4).round() % 2 == 0 ? 1 : -1) *
                          10 *
                          (1 - _shakeCtrl.value)
                      : 0.0;
                  return Transform.translate(
                      offset: Offset(dx, 0), child: child);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isOtpStep
                      ? _otpStep(key: const ValueKey('otp'))
                      : _emailStep(key: const ValueKey('email')),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _red.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: _red, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error,
                            style: const TextStyle(color: _red, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              _buildButton(
                label: _isOtpStep ? 'Verify & Start Shift' : 'Send OTP',
                onTap: _isLoading ? null : (_isOtpStep ? _verifyOtp : _sendOtp),
                loading: _isLoading,
              ),
              if (_isOtpStep) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isLoading ? null : _sendOtp,
                  child: const Text.rich(TextSpan(
                    text: "Didn't receive it?  ",
                    style: TextStyle(color: _grey, fontSize: 13),
                    children: [
                      TextSpan(
                          text: 'Resend OTP',
                          style: TextStyle(
                              color: _blue, fontWeight: FontWeight.w700)),
                    ],
                  )),
                ),
              ],
              const SizedBox(height: 48),
              Text('Secured by Savorya POS',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Column(children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: _blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: const Icon(Icons.restaurant_menu_rounded,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        RichText(
            text: const TextSpan(
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          children: [
            TextSpan(text: 'Savorya', style: TextStyle(color: _dark)),
            TextSpan(text: ' Staff', style: TextStyle(color: _blue)),
          ],
        )),
        const SizedBox(height: 6),
        const Text('Restaurant Management System',
            style: TextStyle(fontSize: 13, color: _grey)),
      ]);

  Widget _buildStepBar() => Row(children: [
        _dot(1, true, done: _isOtpStep),
        Expanded(
            child: Container(height: 2, color: _isOtpStep ? _blue : _border)),
        _dot(2, _isOtpStep),
      ]);

  Widget _dot(int n, bool active, {bool done = false}) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? _blue : Colors.white,
          border: Border.all(color: active ? _blue : _border, width: 1.5),
        ),
        child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text('$n',
                    style: TextStyle(
                        color: active ? Colors.white : _grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w700))),
      );

  Widget _emailStep({Key? key}) => Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back 👋',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
          const SizedBox(height: 6),
          const Text('Enter your User ID to receive a one-time code',
              style: TextStyle(fontSize: 14, color: _grey, height: 1.5)),
          const SizedBox(height: 24),
          const Text('User ID',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _sendOtp(),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: _dark),
            decoration: InputDecoration(
              hintText: 'e.g. you@restaurant.com',
              hintStyle:
                  const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: Color(0xFF9CA3AF), size: 20),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _blue, width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      );

  Widget _otpStep({Key? key}) => Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              onTap: _goBack,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15, color: _dark),
              ),
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Check your inbox',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _dark)),
                Text('Code sent to ${_emailCtrl.text.trim()}',
                    style: const TextStyle(fontSize: 13, color: _grey),
                    overflow: TextOverflow.ellipsis),
              ],
            )),
          ]),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                6,
                (i) => SizedBox(
                      width: 48,
                      height: 58,
                      child: TextField(
                        controller: _otpCtrls[i],
                        focusNode: _otpNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _dark),
                        onChanged: (v) => _otpChanged(v, i),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: _border, width: 1.5)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: _blue, width: 2)),
                        ),
                      ),
                    )),
          ),
        ],
      );

  Widget _buildButton({
    required String label,
    required VoidCallback? onTap,
    required bool loading,
  }) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: active
                  ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                  : [const Color(0xFFE5E7EB), const Color(0xFFE5E7EB)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: _blue.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ]
              : [],
        ),
        child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(label,
                    style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF9CA3AF),
                        fontSize: 15,
                        fontWeight: FontWeight.w700))),
      ),
    );
  }
}
