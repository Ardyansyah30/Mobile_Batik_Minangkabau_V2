import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/quickalert.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'batik_result_page.dart';
import 'history_page.dart';
import 'package:batik/services/api_service.dart';
import 'login_page.dart';

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
  final double _confidenceThreshold = 0.2;

  final Map<String, Map<String, String>> _batikInfo = {
    // ... (map _batikInfo tetap sama)
    'MOTIF BATIK AKA BAJELO': {
      'origin': 'Minangkabau (Sumatera Barat)',
      'philosophy': '''Motif aka bajelo mengandung arti bahwa tanaman yang memiliki akar yang saling menjalar dan menyatu.Hal ini mencerminkan adanya keselarasan dan kerja sama antar tiga tungku sajarangan pada figur di lingkungan sosial dan masyarakat adatMinangkabau, yaitu alim ulama, cerdik pandai, dan ninik mamak.Ketiga unsur inisaling terhubung dalam satu kesatuan yang harmonis,yang menciptakan kerukunandalam nagari.''',
    },
    'MOTIF BATIK AYAM KUKUAK BALENGGEK': {
      'origin': 'Solok, Sumatera Barat',
      'philosophy': '''Motif ini diciptakan oleh pemilik batik Salingka Tabek seorang entrepreneur muda generasi Milenial yaitu , Yusrizal karena terinspirasi melihat kokoh dan megahnya patung ayam yang berada di pusat Kabupaten yaitu dekat dari kantor Bupati Kabupaten Solok. Kemegahan ini mencerminkan kuatnya peran pemimpin dalam melindungi masyarakat nya.''',
    },
    'MOTIF BATIK BURUNG KUAUW': {
      'origin': 'Hutan tropis Sumatera Barat',
      'philosophy': '''Burung kuaw termasuk jenis burung langka yang hanya ada di Sumatera Barat. Burung yang memiliki bulu yang indah dan tidak kalah indah dengan burung merak.Keindahan bulu burung kuaw ini menginsiprasi pemilik rumah batik Salingka Tabek menuangkan nya dalam motif batik jenis batik tulis yang di tulis di atas secarik kain dengan bentuk yang indah. Keindahan tersebut mencerminkan filosofi bahwa keindahan akan memancarkan kebaikan, keluhuran budi dan manfaat bagi orang banyak. Keindahan akan memancarkan semangat untuk memberikan yang terbaik bagi orang banyak''',
    },
    'MOTIF BATIK BURUNG MAKAN PADI': {
      'origin': 'Solok, Sumatera barat',
      'philosophy': '''Motif burung makan padi ini mendeskripsikan burung yang menggambarkan kegembiraannya memakan padi di sawah. Buliran padi yang bernas menjadi hal yang menyenangkan bagi burung pemakan padi. Padi yang mengguning dihamparan sawah petani yang luas di deskripsikan oleh pemilik batik Salingka Tabek menjadi kekuatan hubungan antar makluk yang saling memiliki ketergantungan satu sama lain..''',
    },
    'MOTIF BATIK ITIAK PULANG PATANG': {
      'origin': 'Minangkabau, Sumatera Barat',
      'philosophy': '''Motif itiak pulang patang mendeskripsikan bahwa masyarakat Minang Kabau merupakan komunitas yang kental dengan toleransi. Ada nya toleransi yang baik ditandai dengan barisan panjang itik yang selaras dan segaris dalam mengikuti barisan yang teratur dan terpola. Hal ini juga menggambarkan bahwa dalam adat Minang Kabau pemimpin didahulukan selangkah dan ditinggikan seranting.Barisan itik juga memberikan filosofi bahwa pemimpin yang amanah akan diikuti oleh anggotanya baik dalam sikap maupun dalam perbuatan''',
    },
    'MOTIF BATIK MALABUIK PADI (TULIS)': {
      'origin': 'Solok, Sumatera barat',
      'philosophy': '''Motif batik tulis ini mendeskripsikan setelah panen padi di sawah, di lanjutkan dengan kegiatan melambuik padi (Bahasa Indonesia: memukul padi ke suatu objek untuk merontokkan padi dari tangkai/ batang padi) atau memisahkan padi dari tangkai/ batangnya dengan cara memukulkannya pada ke sebuah wadah (objek) . Kegiatan ini mengedepankan nilai-nilai gotong-royong dalam hubungan masyarakat yang sama-sama memiliki Lokasi persawahan yang berdekatan. Budaya malambuik padi memiliki local wisdom yang unik dan lestari sampai saat ini khususnya masyarakat yang berada di kabupaten di provinsi Sumatera Barat.Kekuatan dari kearifan lokal ini lah yang diusung oleh pemilik sekaligus pencipta motif.''',
    },
    'MOTIF BATIK RANCAK KABUPATEN SOLOK': {
      'origin': 'Solok, Sumatera barat',
      'philosophy': '''Keindahan alam di kabupaten Solok menginsprasi pemilik batik Salingka Tabek mendeskripsikannya dalam sentuhan tangan yang indah di atas kain polos yang berkualitas .Keindahan alam di kabupaten Solok memberikan rasa syukur dan dimanifestasikan dalam motif batik yang menggambarkan keindahan kabupaten Solok dengan kehadiran gunung Talang, Danau Di Atas dan Danau di Bawah ,Danau Singkarak serta keindahan alam lainnya yang dimiliki oleh Kabupaten Solok.''',
    },
    'MOTIF BATIK RUMAH GADANG URANG KOTO BARU': {
      'origin': 'Solok Selatan, Sumatera Barat',
      'philosophy': '''Motif batik ini menggambarkan kekhasan rumah gadang bagonjong yang dimiliki oleh nagari Koto Tuo yang dikenal dengan Nagari Seribu Rumah Gadang yang berada di Kabupaten Solok Selatan ,yaitu bertetanggaan dengan Kabupaten Solok. Nagari ini memiliki rumah gadang bagonjong yang relatif banyak jumlahnya dibanding dengan daerah/ kabupaten lain. Sehingga motif ini menjadi inspirasi baru bagi pemilik sekaligus pencipta motif ini yaitu Yusrizal.''',
    },
    'MOTIF BATIK RUMAH GADANG USANG': {
      'origin': 'Solok,Sumatera Barat',
      'philosophy': '''Motif rumah gadang usang ini mencerminkan bahwa dalam kehidupan ini akan selalu ada regenerasi. Kehadiran rumah gadang usang menjadi sejarah yang menggambarkan prototype , kehidupan dari generasi sebelumnya. Dimana menggambarkan kehidupan generasi sebelumnya yang sangat bersahaja dan ramah dengan alam sekitarnya. Rumah gadang using juga menggambarkan sebuah bukti bahwa kehidupan pernah ada di rumah tersebut yang sudah berlangsung lama dari satu generasi ke generasi berikutnya. Karena itu rumah gadang usingperlu tetap di jaga dengan tetap melestarikannya menjadi asset yang bernilai filosofi tinggi.'''
    },
    'MOTIF BATIK RUMAH GADANG': {
      'origin': 'Sumatera Barat',
      'philosophy': '''Motif Rumah Gadang melambangkan kebersamaan, kekerabatan, dan nilai musyawarah dalam adat Minangkabau. Rumah Gadang tidak hanya sebagai tempat tinggal, tapi juga pusat kehidupan sosial dan adat. Dalam batik, motif ini mencerminkan jati diri, struktur matrilineial, dan penghormatan terhadap leluhur dan nilai tradisional. Setiap lekukan dan susunan motifnya menggambarkan kerukunan antar keluarga besar yang tinggal dalam satu rumah gadang serta tingginya kedudukan perempuan dalam struktur adat Minang.'''
    }
  };

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
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

    // Sanitasi dan limitasi string
    String safeBatikName = (batikName ?? '').trim();
    String safeDescription = (description ?? '').trim();
    String safeOrigin = (origin ?? '').trim();
    if (safeBatikName.length > 100) safeBatikName = safeBatikName.substring(0, 100);
    if (safeDescription.length > 1000) safeDescription = safeDescription.substring(0, 1000);
    if (safeOrigin.length > 100) safeOrigin = safeOrigin.substring(0, 100);

    // Debug print semua field
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
        Navigator.of(context).pop(); // Menutup pop-up loading setelah upload
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
        Navigator.of(context).pop(); // Menutup pop-up loading jika terjadi error
        _showAlert(
          type: QuickAlertType.error,
          title: 'Error Koneksi',
          text: 'Gagal terhubung ke server: \\$e',
        );
      }
      print('❌ Error koneksi: \\$e');
    }
  }

  // Helper: cari key paling mirip dari _batikInfo
  String? _findClosestBatikKey(String label) {
    String normalized(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    String normLabel = normalized(label);

    // Logika pencarian yang diperbaiki
    for (final key in _batikInfo.keys) {
      if (normalized(key) == normLabel) {
        print('✅ Ditemukan kecocokan persis: $key');
        return key;
      }
    }
    // Fallback: cari yang mengandung kata kunci utama jika kecocokan persis gagal
    for (final key in _batikInfo.keys) {
      if (normalized(key).contains(normLabel) || normLabel.contains(normalized(key))) {
        print('✅ Ditemukan kecocokan parsial: $key');
        return key;
      }
    }
    print('❌ Tidak ada kecocokan yang ditemukan untuk label: $label');
    return null;
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
      final List<double> probabilities = [];
      for (int i = 0; i < output[0].length; i++) {
        probabilities.add((output[0][i] - _outputZeroPoint) * _outputScale);
      }
      final Map<String, double> predictionMap = {};
      for (int i = 0; i < _labels.length; i++) {
        predictionMap[_labels[i]] = probabilities[i];
      }
      final sortedPredictions = predictionMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topPrediction = sortedPredictions.first;

      if (mounted) {
        Navigator.of(context).pop();
      }

      String predictedName = topPrediction.key.trim();
      print('Label mentah dari model: "${topPrediction.key}"');
      String? matchedKey = _findClosestBatikKey(predictedName);
      final batikInfoEntry = matchedKey != null ? _batikInfo[matchedKey] : null;
      final bool isMinangkabauBatik = batikInfoEntry != null;
      final String batikOrigin = batikInfoEntry?['origin'] ?? 'Tidak diketahui';
      final String batikPhilosophy = batikInfoEntry?['philosophy'] ?? 'Filosofi tidak tersedia.';
      final String batikNameForBackend = matchedKey ?? predictedName;

      if (topPrediction.value < _confidenceThreshold) {
        if (mounted) {
          _showAlert(
            type: QuickAlertType.warning,
            title: 'Batik Tidak Dikenali',
            text: 'Kami tidak dapat mengidentifikasi motif batik. Mohon coba gambar lain.',
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
        print('Prediksi: Tidak Diketahui, Confidence: \\${topPrediction.value}');
        await _sendToBackend(
          isMinangkabauBatik: false,
          batikName: 'Tidak Diketahui',
          description: 'Gambar tidak dapat diidentifikasi sebagai motif batik Minangkabau.',
          origin: 'Tidak diketahui',
        );
      } else {
        final double batikConfidence = topPrediction.value;
        final double cappedConfidence = batikConfidence > 1.0 ? 1.0 : batikConfidence;
        print('Prediksi: \\${batikNameForBackend}, Confidence: \\${cappedConfidence}');
        print('Origin: \\${batikOrigin}');
        print('Philosophy: \\${batikPhilosophy}');
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
                batikConfidence: cappedConfidence,
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
          text: 'Gagal memprediksi gambar: \\${e}',
        );
      }
      print('❌ Error saat prediksi: \\${e}');
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

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
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