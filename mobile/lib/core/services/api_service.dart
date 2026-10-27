import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Set HER_SPACE_API_URL at build time for the target device/server.
  static const String baseUrl = String.fromEnvironment(
    'HER_SPACE_API_URL',
    defaultValue: 'https://herspace-backend-irtl.onrender.com/api',
  );
  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString('auth_token');
  static Future<void> saveToken(String token) async =>
      (await SharedPreferences.getInstance()).setString('auth_token', token);
  static Future<void> logout() async =>
      (await SharedPreferences.getInstance()).remove('auth_token');
  static Map<String, String> _headers(String? token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  static Future<http.Response> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl/$path').replace(queryParameters: query);
    final token = await getToken();
    final headers = _headers(token);
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'PUT':
        return http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported method $method');
    }
  }

  static Future<http.Response> login(String email, String password) =>
      request('POST', 'login', body: {'email': email, 'password': password});
  static Future<http.Response> register(
    String name,
    String email,
    String password,
  ) => request(
    'POST',
    'register',
    body: {'name': name, 'email': email, 'password': password},
  );
  static Future<http.Response> uploadPortrait(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/potret/upload'),
    );
    final token = await getToken();
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.files.add(await http.MultipartFile.fromPath('photo', file.path));
    return http.Response.fromStream(await request.send());
  }

  static Future<http.Response> uploadAvatar(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/avatar'),
    );
    final token = await getToken();
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.files.add(await http.MultipartFile.fromPath('avatar', file.path));
    return http.Response.fromStream(await request.send());
  }

  static Map<String, dynamic> decode(http.Response response) =>
      Map<String, dynamic>.from(jsonDecode(response.body) as Map);
}
