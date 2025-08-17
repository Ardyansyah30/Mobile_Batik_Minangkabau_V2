import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:intl/intl.dart';
import 'detail_page.dart';
import '../services/api_service.dart';

// Model untuk merepresentasikan data Batik
class Batik {
  final int id;
  final String batikName;
  final String description;
  final String origin;
  final String? imageUrl;
  final DateTime createdAt;

  Batik({
    required this.id,
    required this.batikName,
    required this.description,
    required this.origin,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Batik.fromJson(Map<String, dynamic> json) {
    String? rawImageUrl = json['image_url'] as String?;
    String? displayImageUrl = rawImageUrl;

    if (rawImageUrl != null) {
      // Periksa apakah URL sudah lengkap (dimulai dengan 'http')
      if (!rawImageUrl.startsWith('http')) {
        // Jika belum, gabungkan dengan base URL
        displayImageUrl = ApiService.baseUrl + rawImageUrl;
      }

      // Kemudian, jika URL masih mengarah ke localhost, sesuaikan untuk emulator
      if (displayImageUrl != null && displayImageUrl.startsWith('http://localhost:8000')) {
        displayImageUrl = displayImageUrl.replaceFirst('http://localhost:8000', 'http://10.0.2.2:8000');
      } else if (displayImageUrl != null && displayImageUrl.startsWith('http://127.0.0.1:8000')) {
        displayImageUrl = displayImageUrl.replaceFirst('http://127.0.0.1:8000', 'http://10.0.2.2:8000');
      }
      // Untuk perangkat fisik, pastikan IP lokal komputer Anda sudah benar
      // contoh: 'http://192.168.1.100:8000'
    }

    return Batik(
      id: json['id'],
      batikName: json['batik_name'] ?? 'Tidak Diketahui',
      description: json['description'] ?? 'Tidak ada deskripsi.',
      origin: json['origin'] ?? 'Tidak diketahui',
      imageUrl: displayImageUrl, // Gunakan URL yang sudah disesuaikan
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Batik> _batiks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyBatiks();
  }

  Future<void> _fetchMyBatiks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<dynamic> batikDataList = await ApiService.getMyBatiks();

      // DEBUG PRINT
      print('✅ Berhasil mengambil ${batikDataList.length} data riwayat.');
      
      setState(() {
        _batiks = batikDataList.map((json) => Batik.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan: $e';
      });
      print('❌ Error koneksi: $e');
    }
  }

  void _showAlert({
    required QuickAlertType type,
    required String title,
    required String text,
  }) {
    if (!mounted) return;
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

  Future<void> _deleteBatik(int id, int index) async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Konfirmasi',
      text: 'Apakah Anda yakin ingin menghapus riwayat ini?',
      confirmBtnText: 'Ya',
      cancelBtnText: 'Tidak',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context); // Tutup dialog konfirmasi
        final response = await ApiService.deleteBatik(id);

        if (response.statusCode == 200) {
          _showAlert(
            type: QuickAlertType.success,
            title: 'Berhasil',
            text: 'Riwayat berhasil dihapus.',
          );
          setState(() {
            _batiks.removeAt(index);
          });
        } else {
          final responseBody = json.decode(response.body);
          _showAlert(
            type: QuickAlertType.error,
            title: 'Gagal',
            text: 'Gagal menghapus riwayat: ${responseBody['message']}',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Deteksi',
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
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey,
                child: const Center(
                  child: Text(
                    'Background image not found',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    if (_batiks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Anda belum memiliki riwayat deteksi. Unggah gambar untuk memulai!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _batiks.length,
      itemBuilder: (context, index) {
        final batik = _batiks[index];
        final formattedDate = DateFormat('dd MMMM yyyy').format(batik.createdAt);
        return Card(
          color: Colors.white.withOpacity(0.8),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: batik.imageUrl != null
                  ? Image.network(
                batik.imageUrl!, // BARIS YANG TELAH DIPERBAIKI
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Gagal memuat gambar dari URL: ${batik.imageUrl}');
                  return const Icon(Icons.broken_image, size: 80);
                },
              )
                  : const Icon(Icons.image_not_supported, size: 80),
            ),
            title: Text(
              batik.batikName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asal: ${batik.origin}',
                  style: const TextStyle(color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Diunggah pada: $formattedDate',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteBatik(batik.id, index),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(
                    batik: batik,
                    // HAPUS BARIS DI BAWAH INI
                    // backendApiUrl: ApiService.baseUrl,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}