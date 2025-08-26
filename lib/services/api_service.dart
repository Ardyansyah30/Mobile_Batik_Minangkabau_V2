// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String apiUrl = '$baseUrl/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> saveUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('username');
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

  static Future<http.Response> forgotPassword(String email) async {
    try {
      final url = Uri.parse('$apiUrl/forgot-password');
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {'email': email},
      );
      return response;
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<http.Response> resetPassword(
      String email, String token, String password, String passwordConfirmation) async {
    try {
      final url = Uri.parse('$apiUrl/reset-password');
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<List<dynamic>> getMyBatiks() async {
    final token = await getToken();
    if (token == null) {
      // Jika token tidak ada, langsung lempar exception.
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
    } else if (response.statusCode == 401) {
      // Jika server mengembalikan 401, lempar exception.
      throw Exception('Unauthenticated.');
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
      // Jika token tidak ada, lempar exception.
      throw Exception('Unauthenticated.');
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
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 401) {
      // Jika server mengembalikan 401, lempar exception.
      throw Exception('Unauthenticated.');
    }
    return response;
  }

  static Future<http.Response> deleteBatik(int batikId) async {
    final token = await getToken();
    if (token == null) {
      // Jika token tidak ada, lempar exception.
      throw Exception('Unauthenticated.');
    }

    final url = Uri.parse('$apiUrl/batiks/$batikId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      // Jika server mengembalikan 401, lempar exception.
      throw Exception('Unauthenticated.');
    }
    return response;
  }

  static Future<http.Response> deleteAllBatiks() async {
    final token = await getToken();
    if (token == null) {
      // Jika token tidak ada, lempar exception.
      throw Exception('Unauthenticated.');
    }

    final url = Uri.parse('$apiUrl/histories/clear-all');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      // Jika server mengembalikan 401, lempar exception.
      throw Exception('Unauthenticated.');
    }
    return response;
  }
}