import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static List<Map<String, dynamic>>? _tournamentsCache;
  static String? _tournamentsCacheToken;

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

  bool _isAuthError(http.Response response) {
    return response.statusCode == 401 || response.statusCode == 403;
  }

  void _ensureNotAuthError(http.Response response) {
    if (_isAuthError(response)) {
      _throwAuthExpired();
    }
  }

  Never _throwAuthExpired() {
    throw Exception('AUTH_EXPIRED');
  }

  Future<String?> login(final String username, final String password) async {
    final String basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    final response = await _client
        .post(
          _uri('/api/v1/users/auth/token'),
          headers: <String, String>{
            'Authorization': basicAuth,
            'Content-Type': 'application/json; charset=UTF-8',
          },
        )
        .timeout(const Duration(seconds: 8));

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
    _ensureNotAuthError(response);
    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getTournaments(
    String token, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _tournamentsCache != null &&
        _tournamentsCacheToken == token) {
      return _tournamentsCache!;
    }

    final response = await _client.get(
      _uri('/api/v1/tournaments'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    _ensureNotAuthError(response);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        final items =
            decoded.whereType<Map<String, dynamic>>().toList(growable: false);
        _tournamentsCache = items;
        _tournamentsCacheToken = token;
        return items;
      }
      throw Exception('Unexpected tournaments response');
    }
    throw Exception('Failed to load tournaments: ${response.body}');
  }

  Future<void> createTournament(
    String token, {
    required String id,
    required String name,
    required String description,
    required String location,
    required int passesTotal,
    required int arrowsPerPass,
    required String targetFace,
    required String status,
    required bool hostShoots,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/tournaments/'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'id': id,
        'name': name,
        'description': description,
        'location': location,
        'passesTotal': passesTotal,
        'arrowsPerPass': arrowsPerPass,
        'targetFace': targetFace,
        'status': status,
        'hostShoots': hostShoots,
      }),
    );

    _ensureNotAuthError(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _tournamentsCache = null;
      _tournamentsCacheToken = null;
      return;
    }
    throw Exception('Failed to create tournament: ${response.body}');
  }

  Future<void> deleteTournament(
    String token, {
    required String tournamentId,
  }) async {
    final response = await _client.delete(
      _uri('/api/v1/tournaments/$tournamentId'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    _ensureNotAuthError(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _tournamentsCache = null;
      _tournamentsCacheToken = null;
      return;
    }
    throw Exception('Failed to delete tournament: ${response.body}');
  }

  Future<void> updateTournamentStatus(
    String token, {
    required String tournamentId,
    required String status,
  }) async {
    final response = await _client.patch(
      _uri('/api/v1/tournaments/$tournamentId/status'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    _ensureNotAuthError(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _tournamentsCache = null;
      _tournamentsCacheToken = null;
      return;
    }
    throw Exception('Failed to update tournament status: ${response.body}');
  }

  Future<void> updateTournamentDetails(
    String token, {
    required String tournamentId,
    required String name,
    required String description,
    required String location,
    required int passesTotal,
    required int arrowsPerPass,
    required String targetFace,
    required String status,
    required bool hostShoots,
  }) async {
    final response = await _client.patch(
      _uri('/api/v1/tournaments/$tournamentId'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'location': location,
        'passesTotal': passesTotal,
        'arrowsPerPass': arrowsPerPass,
        'targetFace': targetFace,
        'status': status,
        'hostShoots': hostShoots,
      }),
    );

    _ensureNotAuthError(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _tournamentsCache = null;
      _tournamentsCacheToken = null;
      return;
    }
    throw Exception('Failed to update tournament details: ${response.body}');
  }

  Future<void> addTournamentParticipant(
    String token, {
    required String tournamentId,
    required String displayName,
    required int targetNo,
    required String targetFace,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/tournaments/$tournamentId/participant'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'displayName': displayName,
        'targetNo': targetNo,
        'targetFace': targetFace,
      }),
    );

    _ensureNotAuthError(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _tournamentsCache = null;
      _tournamentsCacheToken = null;
      return;
    }
    throw Exception('Failed to add tournament participant: ${response.body}');
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
