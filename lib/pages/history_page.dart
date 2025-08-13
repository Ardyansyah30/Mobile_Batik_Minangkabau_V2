import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
    return Batik(
      id: json['id'],
      batikName: json['batik_name'] ?? 'Tidak Diketahui',
      description: json['description'] ?? 'Tidak ada deskripsi.',
      origin: json['origin'] ?? 'Tidak diketahui',
      imageUrl: json['image_url'] as String?,
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
  final String _backendApiUrl = 'http://10.79.229.212:8000';
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

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Anda harus login untuk melihat riwayat.';
        });
      }
      return;
    }

    final url = Uri.parse('$_backendApiUrl/api/histories');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['histories'];

        setState(() {
          _batiks = data.map((json) => Batik.fromJson(json)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi Anda telah habis. Silakan login kembali.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Gagal mengambil data riwayat: ${response.statusCode}';
        });
        print('Error fetching data: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan koneksi: $e';
      });
      print('Error: $e');
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

  // ✅ Fungsi untuk menghapus riwayat
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
          _showAlert(
            type: QuickAlertType.error,
            title: 'Gagal',
            text: 'Gagal menghapus riwayat: ${json.decode(response.body)['message']}',
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
      body: _buildBody(),
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
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: batik.imageUrl != null
                  ? Image.network(
                '$_backendApiUrl${batik.imageUrl}',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
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
                    backendApiUrl: _backendApiUrl,
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