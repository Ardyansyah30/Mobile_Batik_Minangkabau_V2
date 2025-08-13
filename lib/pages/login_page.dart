import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:batik/pages/upload_page.dart';
import 'package:batik/pages/register_page.dart';
import 'package:batik/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final token = data['access_token'];

          if (token != null) {
            await ApiService.saveToken(token);

            if (mounted) {
              QuickAlert.show(
                context: context, // Perbaikan: Tambah context
                type: QuickAlertType.success,
                title: 'Login Berhasil',
                text: 'Selamat datang kembali!',
                onConfirmBtnTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadPage()),
                        (Route<dynamic> route) => false,
                  );
                },
              );
            }
          } else {
            if (mounted) {
              QuickAlert.show(
                context: context, // Perbaikan: Tambah context
                type: QuickAlertType.error,
                title: 'Login Berhasil, Token Hilang',
                text: 'Server tidak mengembalikan token. Silakan coba login manual.',
              );
            }
          }
        } on FormatException {
          if (mounted) {
            QuickAlert.show(
              context: context, // Perbaikan: Tambah context
              type: QuickAlertType.error,
              title: 'Format Respons Tidak Valid',
              text: 'Server mengembalikan respons yang tidak dapat dibaca.',
            );
          }
        }
      } else {
        if (mounted) {
          String errorMessage = 'Login gagal. Mohon coba lagi.';
          try {
            final errorData = json.decode(response.body);
            if (errorData['errors'] != null) {
              if (errorData['errors']['email'] != null && errorData['errors']['email'].isNotEmpty) {
                errorMessage = errorData['errors']['email'][0];
              }
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } on FormatException {
            errorMessage = 'Gagal membaca respons error dari server. Status: ${response.statusCode}';
          }
          QuickAlert.show(
            context: context, // Perbaikan: Tambah context
            type: QuickAlertType.error,
            title: 'Login Gagal',
            text: errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context, // Perbaikan: Tambah context
          type: QuickAlertType.error,
          title: 'Koneksi Gagal',
          text: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
      }
      print('❌ Error saat login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Selamat Datang Kembali!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Masukkan email yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 8) {
                          return 'Password minimal 8 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        );
                      },
                      child: const Text(
                        'Belum punya akun? Daftar di sini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}