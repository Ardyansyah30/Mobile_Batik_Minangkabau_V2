import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:batik/pages/login_page.dart';
import 'package:batik/pages/upload_page.dart';
import 'package:batik/services/api_service.dart';
import 'package:batik/main_layout.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final token = data['access_token'];
          final user = data['user'];

          if (token != null && user != null && user['name'] != null) {
            await ApiService.saveToken(token);
            await ApiService.saveUsername(user['name']);

            if (mounted) {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: 'Registrasi Berhasil',
                text: 'Akun Anda berhasil dibuat!',
                onConfirmBtnTap: () {
                  // Ganti baris ini untuk navigasi ke MainLayout
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainLayout()),
                        (Route<dynamic> route) => false,
                  );
                },
              );
            }
          } else {
            if (mounted) {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                title: 'Registrasi Berhasil, Token Hilang',
                text: 'Silakan coba login manual untuk mendapatkan token.',
                onConfirmBtnTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              );
            }
          }
        } on FormatException {
          if (mounted) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Format Respons Tidak Valid',
              text: 'Server mengembalikan respons yang tidak dapat dibaca.',
            );
          }
        }
      } else {
        if (mounted) {
          String errorMessage = 'Registrasi gagal. Mohon coba lagi.';
          try {
            final errorData = json.decode(response.body);
            if (errorData['errors'] != null) {
              if (errorData['errors']['email'] != null && errorData['errors']['email'].isNotEmpty) {
                errorMessage = errorData['errors']['email'][0];
              } else if (errorData['message'] != null) {
                errorMessage = errorData['message'];
              }
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } on FormatException {
            errorMessage = 'Gagal membaca respons error dari server. Status: ${response.statusCode}';
          }
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Registrasi Gagal',
            text: errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Koneksi Gagal',
          text: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
      }
      print('❌ Error saat registrasi: $e');
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
      appBar: AppBar(
        title: const Text('Daftar Akun', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF8B4513),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                      'Daftar Akun Baru',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
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
                      onPressed: _isLoading ? null : _register,
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
                        'Daftar',
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
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Sudah punya akun? Login di sini',
                        style: TextStyle(
                          color: Colors.black,
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