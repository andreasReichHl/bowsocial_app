import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {

  String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;

    // Optional via .env
    final fromEnv = dotenv.env['BASE_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    // Fallbacks
    const isProd = bool.fromEnvironment('dart.vm.product');
    return isProd ? 'https://example.com' : 'http://127.0.0.1:8080';
  }

  Future<String?> login(final String username, final String password) async {
    final String basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/users/auth/token'),
      headers: <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['token'];
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
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