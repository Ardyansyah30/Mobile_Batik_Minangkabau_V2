import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

@immutable
class BatikModel {
  final String name;
  final String origin;
  final String philosophy;
  final String? imageUrl;

  const BatikModel({
    required this.name,
    required this.origin,
    required this.philosophy,
    this.imageUrl,
  });

  factory BatikModel.fromJson(Map<String, dynamic> json) {
    return BatikModel(
      name: json['batik_name'] as String,
      origin: json['origin'] as String,
      philosophy: json['description'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; ////http://10.0.2.2:8000 ///////http://192.168.1.5:8000
  static const String apiUrl = '$baseUrl/api';

  // --- Fungsi Otentikasi & Penyimpanan Token ---
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

  // --- Fungsi Interaksi Batik ---
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
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated.');
    } else {
      throw Exception('Gagal memuat data riwayat batik: ${response.statusCode}');
    }
  }

  static Future<List<BatikModel>> getBatikInfo() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/batiks'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> batikData = responseData['batiks'] as List<dynamic>;
        return batikData.map((json) {
          return BatikModel.fromJson(json as Map<String, dynamic>);
        }).toList();
      } else {
        debugPrint('Failed to load batik info. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching batik info: $e');
      return [];
    }
  }

  static Future<BatikModel?> getBatikByName(String name) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/batiks?batik_name=$name'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> batikData = responseData['batiks'] as List<dynamic>;
        if (batikData.isNotEmpty) {
          return BatikModel.fromJson(batikData.first as Map<String, dynamic>);
        }
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching batik by name: $e');
      return null;
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
      throw Exception('Unauthenticated.');
    }
    return response;
  }

  static Future<http.Response> deleteBatik(int batikId) async {
    final token = await getToken();
    if (token == null) {
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
      throw Exception('Unauthenticated.');
    }
    return response;
  }

  static Future<http.Response> deleteAllBatiks() async {
    final token = await getToken();
    if (token == null) {
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
      throw Exception('Unauthenticated.');
    }
    return response;
  }
}