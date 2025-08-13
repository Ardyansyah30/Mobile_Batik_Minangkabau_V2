import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batik/pages/login_page.dart';
import 'package:batik/pages/upload_page.dart';

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
      home: const _AuthCheck(),
    );
  }
}

class _AuthCheck extends StatefulWidget {
  const _AuthCheck();

  @override
  State<_AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<_AuthCheck> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    setState(() {
      _isLoggedIn = token != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B4513)),
        ),
      );
    } else {
      return _isLoggedIn ? const UploadPage() : const LoginPage();
    }
  }
}