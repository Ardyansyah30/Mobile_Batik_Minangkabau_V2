import 'package:flutter/material.dart';
import 'package:batik/pages/upload_page.dart';
import 'package:batik/pages/history_page.dart';
import 'package:batik/pages/profil_page.dart';
import 'package:batik/services/api_service.dart';
import 'package:batik/pages/login_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  late PageController _pageController;
  bool _isCheckingAuth = true;

  final List<Widget> _pages = <Widget>[
    const UploadPage(),
    const HistoryPage(),
    const ProfilPage(), // Perbaikan: Gunakan nama kelas yang benar, yaitu 'ProfilPage'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final token = await ApiService.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
        );
      }
    } else {
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B4513)),
        ),
      );
    }
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Deteksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF8B4513),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFEAE3D6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}