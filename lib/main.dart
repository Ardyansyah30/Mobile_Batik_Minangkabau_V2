import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batik/pages/login_page.dart';
import 'package:batik/main_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Batik App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFEAE3D6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B4513),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Home akan menentukan rute awal berdasarkan status login.
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Ambil instance SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // Ambil token dari SharedPreferences
    final token = prefs.getString('access_token');

    // Perbarui state berdasarkan keberadaan token
    setState(() {
      _isLoggedIn = token != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading indicator saat memeriksa status login
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B4513)),
        ),
      );
    }
    // Tampilkan halaman yang sesuai
    else {
      return _isLoggedIn ? const MainLayout() : const LoginPage();
    }
  }
}
