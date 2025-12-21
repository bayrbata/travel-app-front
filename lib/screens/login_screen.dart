import 'dart:math';
import 'package:flutter/material.dart';
import 'package:travelapp/services/auth_service.dart';
import 'package:travelapp/screens/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();

  late AnimationController _orbitController;
  late AnimationController _flyController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 🌍 Дэлхийн эргэлт
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 🚀 Нисээд гарах
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _orbitController.repeat();
      } else {
        _orbitController.stop();
      }
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _flyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    _flyController.reset();
    await _flyController.forward();

    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _flyController.reset();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Нэвтрэхэд алдаа гарлаа'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const orbitRadius = 80;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEEB), Color(0xFF1E3C72)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🌍 Томруулсан Дэлхий
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Colors.blue.shade400, Colors.indigo.shade900],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.3),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.public,
                            color: Colors.white,
                            size: 150,
                          ),
                        ),
                      ),

                      // ✈️ Plane (yellow icon)
                      AnimatedBuilder(
                        animation: Listenable.merge([_orbitController, _flyController]),
                        builder: (_, child) {
                          final angle = _orbitController.value * 2 * pi;
                          final x = orbitRadius * cos(angle);
                          final y = orbitRadius * sin(angle);

                          return Transform.translate(
                            offset: Offset(
                              x + _flyController.value * 400,
                              y - _flyController.value * 400,
                            ),
                            child: Transform.rotate(
                              angle: angle + pi / 2,
                              child: child,
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.flight_takeoff,
                          size: 48,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        validator: (v) => v!.contains('@') ? null : 'Имэйл буруу',
                        decoration: InputDecoration(
                          labelText: 'Имэйл',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        validator: (v) => v!.length >= 6 ? null : '6+ тэмдэгт',
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Нууц үг',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 60),
                    backgroundColor: Colors.amber.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Нэвтрэх',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
