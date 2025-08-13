import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan URL API backend Anda. Gunakan 10.0.2.2 untuk emulator.http://10.0.2.2:8000
  static const String _baseUrl = 'http://10.79.229.212:8000/api';
  // --- Fungsi untuk Login Pengguna ---
  static Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'email': email,
        'password': password,
      },
    );
    return response;
  }

  // --- Fungsi untuk Registrasi Pengguna ---
  static Future<http.Response> register(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
    return response;
  }

  // --- Fungsi untuk Otentikasi dan Token ---
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ✅ Fungsi untuk Mengambil Data Riwayat Batik
  static Future<http.Response> getMyBatiks() async {
    final token = await getToken();
    if (token == null) {
      return http.Response(json.encode({'message': 'Unauthenticated.'}), 401);
    }

    final url = Uri.parse('$_baseUrl/histories');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return response;
  }

  // --- Fungsi untuk Mengunggah Batik Baru (deteksi atau kontribusi) ---
  static Future<http.Response> uploadBatik({
    required File imageFile,
    required bool isMinangkabauBatik,
    String? batikName,
    String? description,
    String? origin,
  }) async {
    final token = await getToken();
    if (token == null) {
      return http.Response(json.encode({'message': 'Unauthenticated.'}), 401);
    }

    final uri = Uri.parse('$_baseUrl/batiks/store');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    request.fields['is_minangkabau_batik'] = isMinangkabauBatik.toString();

    if (isMinangkabauBatik) {
      request.fields['batik_name'] = batikName ?? '';
      request.fields['description'] = description ?? '';
      request.fields['origin'] = origin ?? '';
    } else {
      request.fields['batik_name'] = 'Bukan Batik Minangkabau';
      request.fields['description'] = 'Gambar bukan motif batik Minangkabau.';
      request.fields['origin'] = 'Tidak diketahui';
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // --- Fungsi untuk Menghapus Riwayat Batik ---
  static Future<http.Response> deleteBatik(int batikId) async {
    final token = await getToken();
    if (token == null) {
      return http.Response(json.encode({'message': 'Unauthenticated.'}), 401);
    }

    final url = Uri.parse('$_baseUrl/batiks/$batikId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return response;
  }
}