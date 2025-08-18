import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.6:8000';
  static const String apiUrl = '$baseUrl/api';

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

  static Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$apiUrl/login');
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

  static Future<http.Response> register(String name, String email, String password) async {
    final url = Uri.parse('$apiUrl/register');
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

  static Future<List<dynamic>> getMyBatiks() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Unauthenticated.');
    }

    final url = Uri.parse('$apiUrl/histories');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['batiks'] as List<dynamic>? ?? [];
    } else {
      throw Exception('Gagal memuat data riwayat batik: ${response.statusCode}');
    }
  }

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

    final uri = Uri.parse('$apiUrl/batiks/store');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    request.fields['is_minangkabau_batik'] = isMinangkabauBatik.toString();

    if (batikName != null && batikName.isNotEmpty) {
      request.fields['batik_name'] = batikName;
    }
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }
    if (origin != null && origin.isNotEmpty) {
      request.fields['origin'] = origin;
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  static Future<http.Response> deleteBatik(int batikId) async {
    final token = await getToken();
    if (token == null) {
      return http.Response(json.encode({'message': 'Unauthenticated.'}), 401);
    }

    final url = Uri.parse('$apiUrl/batiks/$batikId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return response;
  }

  // FUNGSI BARU: Hapus SEMUA Riwayat Batik
  static Future<http.Response> deleteAllBatiks() async {
    final token = await getToken();
    if (token == null) {
      return http.Response(json.encode({'message': 'Unauthenticated.'}), 401);
    }

    final url = Uri.parse('$apiUrl/histories/clear-all');
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