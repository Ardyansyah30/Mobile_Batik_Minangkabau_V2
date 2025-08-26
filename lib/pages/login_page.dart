// lib/pages/login_page.dart

import 'dart:convert'; // Tambahkan import ini untuk menggunakan json.decode
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import '../services/api_service.dart';
import '../main_layout.dart';
import 'register_page.dart';
import 'reset_password_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showAlert(
        type: QuickAlertType.warning,
        title: 'Peringatan',
        text: 'Email dan password tidak boleh kosong.',
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.login(email, password);

      if (mounted) {
        if (response.statusCode == 200) {
          final body = json.decode(response.body);
          final token = body['access_token'];
          final username = body['user']['name'];

          // --- LANGKAH PENTING BARU ---
          // Simpan token otentikasi dan nama pengguna setelah login berhasil
          await ApiService.saveToken(token);
          await ApiService.saveUsername(username);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        } else if (response.statusCode == 401) {
          _showAlert(
            type: QuickAlertType.error,
            title: 'Login Gagal',
            text: 'Email atau password salah. Coba lagi.',
          );
        } else {
          _showAlert(
            type: QuickAlertType.error,
            title: 'Login Gagal',
            text: 'Terjadi kesalahan. Coba lagi nanti.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showAlert(
          type: QuickAlertType.error,
          title: 'Error Koneksi',
          text: 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: 'Lupa Password',
      text: 'Masukkan email Anda untuk mereset password.',
      widget: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ),
      confirmBtnText: 'Reset',
      cancelBtnText: 'Batal',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
        if (emailController.text.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                email: emailController.text,
              ),
            ),
          );
        } else {
          _showAlert(
            type: QuickAlertType.error,
            title: 'Error',
            text: 'Email tidak boleh kosong.',
          );
        }
      },
    );
  }

  void _showAlert({
    required QuickAlertType type,
    required String title,
    required String text,
  }) {
    QuickAlert.show(
      context: context,
      type: type,
      title: title,
      text: text,
      backgroundColor: const Color(0xFFEAE3D6),
      titleColor: Colors.black,
      textColor: Colors.black,
      confirmBtnColor: const Color(0xFF8B4513),
      confirmBtnTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background1.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                color: Colors.white.withOpacity(0.8),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'LOGIN',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: const Text(
                          "Belum punya akun? Daftar",
                          style: TextStyle(color: Color(0xFF8B4513)),
                        ),
                      ),
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          "Lupa Password?",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}