// lib/pages/upload_page.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/quickalert.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'batik_result_page.dart';
import 'history_page.dart';
import 'package:batik/services/api_service.dart';
import 'login_page.dart';
import 'package:batik/batik_data.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _selectedImage;
  Interpreter? _interpreter;
  List<String> _labels = [];
  final int _inputSize = 224;
  bool _isLoading = false;

  final double _outputScale = 0.031607624143362045;
  final int _outputZeroPoint = 184;
  final double _confidenceThreshold = 0.3;

  late String _appDocumentPath;

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
    _initAppDocumentPath();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _initAppDocumentPath() async {
    final directory = await getApplicationDocumentsDirectory();
    _appDocumentPath = directory.path;
  }

  Future<void> _loadModelAndLabels() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _interpreter = await Interpreter.fromAsset('assets/my_model_quantized_uint8.tflite');
      String labelsData = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      print("✅ Model dan label berhasil dimuat.");
    } catch (e) {
      print("❌ Gagal memuat model atau label: $e");
      if (mounted) {
        _showAlert(
          type: QuickAlertType.error,
          title: 'Error Inisialisasi',
          text: 'Gagal memuat model atau label. Aplikasi mungkin tidak berfungsi dengan benar.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<List<List<List<int>>>>> _preprocessImageForUint8Model(File imageFile) async {
    Uint8List imageBytes = await imageFile.readAsBytes();
    ui.Image originalImage = await decodeImageFromList(imageBytes);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final srcRect = Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, _inputSize.toDouble(), _inputSize.toDouble());
    canvas.drawImageRect(originalImage, srcRect, dstRect, Paint());
    final img = await recorder.endRecording().toImage(_inputSize, _inputSize);
    final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final Uint8List rgbaBytes = byteData!.buffer.asUint8List();
    List<List<List<List<int>>>> input = List.generate(
      1,
          (i) => List.generate(
        _inputSize,
            (j) => List.generate(
          _inputSize,
              (k) => List.generate(
            3,
                (l) => 0,
          ),
        ),
      ),
    );
    for (int i = 0; i < _inputSize; i++) {
      for (int j = 0; j < _inputSize; j++) {
        int index = (i * _inputSize + j) * 4;
        final r = rgbaBytes[index];
        final g = rgbaBytes[index + 1];
        final b = rgbaBytes[index + 2];
        input[0][i][j][0] = r;
        input[0][i][j][1] = g;
        input[0][i][j][2] = b;
      }
    }
    return input;
  }

  Future<void> _savePredictedImage(String batikName) async {
    if (_selectedImage == null) return;
    final cleanedName = batikName.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
    final directoryPath = '$_appDocumentPath/batik_predicted_images/$cleanedName';
    final Directory dir = Directory(directoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('✅ Folder baru berhasil dibuat: $directoryPath');
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.path.split('/').last}';
    final destinationPath = '$directoryPath/$fileName';
    try {
      await _selectedImage!.copy(destinationPath);
      print('✅ Gambar berhasil disalin ke: $destinationPath');
    } catch (e) {
      print('❌ Gagal menyalin gambar: $e');
    }
  }

  Future<void> _sendToBackend({
    required bool isMinangkabauBatik,
    String? batikName,
    String? description,
    String? origin,
  }) async {
    if (_selectedImage == null) {
      print('❌ Tidak ada gambar yang dipilih.');
      _showAlert(
        type: QuickAlertType.error,
        title: 'Gagal Mengunggah',
        text: 'Silakan pilih gambar terlebih dahulu.',
      );
      return;
    }
    if (!await _selectedImage!.exists()) {
      print('❌ File gambar tidak ditemukan: \\${_selectedImage!.path}');
      _showAlert(
        type: QuickAlertType.error,
        title: 'File Tidak Ditemukan',
        text: 'File gambar tidak ditemukan di perangkat.',
      );
      return;
    }

    String safeBatikName = (batikName ?? '').trim();
    String safeDescription = (description ?? '').trim();
    String safeOrigin = (origin ?? '').trim();

    print('--- DATA YANG DIKIRIM KE BACKEND ---');
    print('isMinangkabauBatik: \\$isMinangkabauBatik');
    print('batikName: \\$safeBatikName');
    print('description: \\$safeDescription');
    print('origin: \\$safeOrigin');
    print('file path: \\${_selectedImage!.path}');
    print('file size: \\${await _selectedImage!.length()} bytes');
    print('-------------------------------------');

    _showAlert(
      type: QuickAlertType.loading,
      title: 'Mengunggah Data',
      text: 'Mengirim gambar dan hasil prediksi ke server...',
      autoCloseDuration: null,
    );

    try {
      final response = await ApiService.uploadBatik(
        imageFile: _selectedImage!,
        isMinangkabauBatik: isMinangkabauBatik,
        batikName: safeBatikName,
        description: safeDescription,
        origin: safeOrigin,
      );

      if (mounted) {
        Navigator.of(context).pop();
        if (response.statusCode == 201) {
          // Navigasi ke halaman hasil dilakukan di _predictImage
        } else if (response.statusCode == 401) {
          _showAlert(
            type: QuickAlertType.error,
            title: 'Sesi Habis',
            text: 'Token otentikasi tidak valid atau telah kadaluarsa. Silakan login kembali.',
          );
        } else {
          final responseBody = json.decode(response.body);
          _showAlert(
            type: QuickAlertType.error,
            title: 'Error Unggah',
            text: 'Gagal mengunggah gambar. Status: \\${response.statusCode}. Respon: \\${responseBody['message']}',
          );
          print('❌ Error mengunggah: \\${response.statusCode}, Body: \\${response.body}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showAlert(
          type: QuickAlertType.error,
          title: 'Error Koneksi',
          text: 'Gagal terhubung ke server: \\$e',
        );
      }
      print('❌ Error koneksi: \\$e');
    }
  }

  String? _findClosestBatikKey(String label) {
    String normalized(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ');
    String normLabel = normalized(label);

    for (final key in batikInfo.keys) {
      if (normalized(key) == normLabel) {
        print('✅ Ditemukan kecocokan persis: $key');
        return key;
      }
    }
    print('❌ Tidak ada kecocokan yang ditemukan untuk label: $label');
    return null;
  }

  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);
    List<double> expValues = logits.map((logit) => exp(logit - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((e) => e / sumExp).toList();
  }

  Future<void> _predictImage() async {
    if (_selectedImage == null || _interpreter == null || _labels.isEmpty || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _showAlert(
      type: QuickAlertType.loading,
      title: 'Memprediksi',
      text: 'Menganalisis gambar batik...',
      autoCloseDuration: null,
    );

    try {
      final List<List<List<List<int>>>> inputData = await _preprocessImageForUint8Model(_selectedImage!);
      var outputTensor = _interpreter!.getOutputTensor(0);
      var outputShape = outputTensor.shape;
      var output = Uint8List(outputShape.reduce((a, b) => a * b)).reshape(outputShape);
      _interpreter!.run(inputData, output);

      final List<double> logits = [];
      for (int i = 0; i < output[0].length; i++) {
        logits.add((output[0][i] - _outputZeroPoint) * _outputScale);
      }

      final List<double> softmaxProbabilities = _softmax(logits);

      final Map<String, double> predictionMap = {};
      for (int i = 0; i < _labels.length; i++) {
        predictionMap[_labels[i]] = softmaxProbabilities[i];
      }

      final sortedPredictions = predictionMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topPrediction = sortedPredictions.first;

      if (mounted) {
        Navigator.of(context).pop();
      }

      String predictedName = topPrediction.key.trim();
      double batikConfidence = topPrediction.value;

      print('Label mentah dari model: "$predictedName"');

      String? matchedKey = _findClosestBatikKey(predictedName);
      final batikInfoEntry = matchedKey != null ? batikInfo[matchedKey] : null;

      if (batikConfidence < _confidenceThreshold) {
        print('❌ Prediksi: Tidak Diketahui, Confidence: \\$batikConfidence (di bawah ambang batas \\$_confidenceThreshold)');
        await _sendToBackend(
          isMinangkabauBatik: false,
          batikName: 'Tidak Diketahui',
          description: 'Gambar tidak dapat diidentifikasi sebagai motif batik Minangkabau.',
          origin: 'Tidak diketahui',
        );
        if (mounted) {
          _showAlert(
            type: QuickAlertType.warning,
            title: 'Batik Tidak Dikenali',
            text: 'Kami tidak dapat mengidentifikasi motif batik. Mohon coba gambar lain.',
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      } else {
        final bool isMinangkabauBatik = batikInfoEntry != null;
        final String batikOrigin = batikInfoEntry?['origin'] ?? 'Tidak diketahui';
        final String batikPhilosophy = batikInfoEntry?['philosophy'] ?? 'Filosofi tidak tersedia.';
        final String batikNameForBackend = matchedKey ?? predictedName;

        print('Prediksi: \\$batikNameForBackend, Confidence: \\$batikConfidence');
        print('Origin: \\$batikOrigin');
        print('Philosophy: \\$batikPhilosophy');

        await _sendToBackend(
          isMinangkabauBatik: isMinangkabauBatik,
          batikName: batikNameForBackend,
          origin: batikOrigin,
          description: batikPhilosophy,
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BatikResultPage(
                uploadedImage: _selectedImage,
                batikName: batikNameForBackend,
                batikConfidence: batikConfidence,
                batikOrigin: batikOrigin,
                batikPhilosophy: batikPhilosophy,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showAlert(
          type: QuickAlertType.error,
          title: 'Error Prediksi',
          text: 'Gagal memprediksi gambar: \\$e',
        );
      }
      print('❌ Error saat prediksi: \\$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
      if (mounted) {
        _showAlert(
          type: QuickAlertType.success,
          title: 'Gambar Dipilih',
          text: 'Gambar berhasil dipilih!',
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
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

  void _deleteImage() {
    setState(() => _selectedImage = null);
    if (mounted) {
      _showAlert(
        type: QuickAlertType.info,
        title: 'Gambar Dihapus',
        text: 'Gambar telah dihapus dari pratinjau.',
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deteksi Batik',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B4513),
        ),
      )
          : Stack(
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext bc) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAE3D6),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Pilih dari Galeri'),
                                onTap: () {
                                  Navigator.pop(bc);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Ambil dari Kamera'),
                                onTap: () {
                                  Navigator.pop(bc);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE3D6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black54, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 80, color: Colors.black54),
                        SizedBox(height: 10),
                        Text(
                          "Ketuk untuk Memilih Gambar",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (_selectedImage != null && _interpreter != null && _labels.isNotEmpty)
                      ? _predictImage
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "UPLOAD & PREDIKSI",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                if (_selectedImage != null)
                  ElevatedButton(
                    onPressed: _deleteImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "HAPUS GAMBAR",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}