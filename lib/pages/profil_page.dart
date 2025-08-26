// lib/pages/profil_page.dart

import 'package:flutter/material.dart';
import 'package:batik/services/api_service.dart';
import 'package:quickalert/quickalert.dart';
import 'package:batik/pages/reset_password_screen.dart';
import 'package:batik/pages/login_page.dart'; // Tambahkan impor ini

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String? _username;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = await ApiService.getUsername();
    if (mounted) {
      setState(() {
        _username = username;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await ApiService.removeToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _showAlert({
    required QuickAlertType type,
    required String title,
    required String text,
    Duration? autoCloseDuration,
  }) {
    if (!mounted) return;
    QuickAlert.show(
      context: context,
      type: type,
      title: title,
      text: text,
      autoCloseDuration: autoCloseDuration,
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B4513)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                      const Icon(
                        Icons.account_circle,
                        size: 100,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _username ?? 'Pengguna Tidak Ditemukan',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Halaman Profil',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_username != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResetPasswordScreen(
                                  email: _username!,
                                ),
                              ),
                            );
                          } else {
                            _showAlert(
                              type: QuickAlertType.error,
                              title: 'Error',
                              text: 'Email pengguna tidak tersedia. Silakan coba lagi.',
                            );
                          }
                        },
                        icon: const Icon(Icons.lock),
                        label: const Text('Ganti Password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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