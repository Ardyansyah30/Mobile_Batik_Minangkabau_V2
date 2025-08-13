// lib/detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'history_page.dart'; // Import model Batik dari HistoryPage

class DetailPage extends StatelessWidget {
  final Batik batik;
  final String backendApiUrl;

  const DetailPage({
    super.key,
    required this.batik,
    required this.backendApiUrl,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM yyyy').format(batik.createdAt);
    final imageUrl = batik.imageUrl != null
        ? '$backendApiUrl${batik.imageUrl}'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(batik.batikName),
        backgroundColor: const Color(0xFF8B4513),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tampilan Gambar
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 200),
                ),
              ),
            const SizedBox(height: 16),
            // Nama Batik
            Text(
              batik.batikName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Asal
            Text(
              'Asal: ${batik.origin}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Tanggal Unggah
            Text(
              'Diunggah pada: $formattedDate',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deskripsi:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Deskripsi
            Text(
              batik.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}