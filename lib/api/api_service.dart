import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;

    // Optional via .env
    final fromEnv = dotenv.env['BASE_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    // Fallbacks
    return kReleaseMode ? 'https://example.com' : 'http://127.0.0.1:8080';
  }

  Uri _uri(String path) {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalized$path');
  }

  Future<String?> login(final String username, final String password) async {
    final String basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    final response = await _client.post(
      _uri('/api/v1/users/auth/token'),
      headers: <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final token = decoded['token']?.toString();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
      throw Exception('Missing token in response');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('AUTH_INVALID');
    }
    throw Exception('Failed to login: ${response.body}');
  }

  Future<bool> verifyToken(String token) async {
    final response = await _client.get(
      _uri('/api/v1/users/auth/verify'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  Future<http.Response> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) {
    return _client.post(
      _uri(path),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        ...?headers,
      },
      body: jsonEncode(body),
    );
  }
}


class TokenStorage {
  static const _key = 'jwt_token';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
  }

  static Future<String?> readToken() async {
    return _storage.read(key: _key);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _key);
  }
}
