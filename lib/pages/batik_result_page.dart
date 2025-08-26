import 'dart:io';
import 'package:flutter/material.dart';

class BatikResultPage extends StatelessWidget {
  final File? uploadedImage;
  final String batikName;
  final String batikOrigin;
  final String batikPhilosophy;
  final double? batikConfidence;

  const BatikResultPage({
    super.key,
    this.uploadedImage,
    required this.batikName,
    required this.batikOrigin,
    required this.batikPhilosophy,
    this.batikConfidence,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Hasil Identifikasi Batik',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.8),
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Latar belakang gambar
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
          // Konten utama dengan kartu dan informasi
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Kartu gambar yang diunggah
                  _buildResultCard(
                    child: uploadedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        uploadedImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.error_outline, size: 50, color: Colors.black54),
                        ),
                      ),
                    )
                        : const Center(
                      child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Kartu informasi batik
                  _buildInfoCard("Nama Batik", batikName, false),
                  const SizedBox(height: 10),
                  if (batikConfidence != null)
                    _buildInfoCard("Keyakinan Model", "${(batikConfidence! * 100).toStringAsFixed(2)}%", false),
                  const SizedBox(height: 10),
                  _buildInfoCard("Asal Daerah", batikOrigin, false),
                  const SizedBox(height: 10),
                  // Panggilan untuk filosofi dengan isJustified: true
                  _buildInfoCard("Filosofi", batikPhilosophy, true),
                  const SizedBox(height: 30),
                  // Tombol kembali
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.5),
                          border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.8), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Metode untuk membangun kartu hasil
  Widget _buildResultCard({required Widget child}) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.5),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.8), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  // Metode untuk membangun kartu informasi
  Widget _buildInfoCard(String title, String content, bool isJustified) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.5),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.8), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
            textAlign: isJustified ? TextAlign.justify : TextAlign.start,
          ),
        ],
      ),
    );
  }
}