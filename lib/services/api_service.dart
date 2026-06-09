import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('${AppConstants.apiUrl}$endpoint');
      if (queryParams != null) uri = uri.replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _headers());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool auth = true}) async {
    try {
      final uri = Uri.parse('${AppConstants.apiUrl}$endpoint');
      final response = await http.post(
        uri,
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${AppConstants.apiUrl}$endpoint');
      final response = await http.put(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${AppConstants.apiUrl}$endpoint');
      final response = await http.delete(uri, headers: await _headers());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<dynamic> getData(String table, {Map<String, String>? queryParams}) async {
    return get('${AppConstants.dataEndpoint}/$table', queryParams: queryParams);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? body['message'] ?? 'Request failed');
    }
  }
}
