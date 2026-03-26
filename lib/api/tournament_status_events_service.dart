import 'dart:async';
import 'dart:convert';

import 'package:bowsocial_app/api/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class TournamentStatusChangedEvent {
  const TournamentStatusChangedEvent({
    required this.tournamentId,
    required this.oldStatus,
    required this.newStatus,
    required this.changedAt,
    required this.sequence,
  });

  final String tournamentId;
  final String? oldStatus;
  final String? newStatus;
  final DateTime? changedAt;
  final int? sequence;
}

class TournamentStatusEventsService {
  TournamentStatusEventsService._();

  static const bool _enabled = false;

  static final TournamentStatusEventsService instance =
      TournamentStatusEventsService._();

  final StreamController<TournamentStatusChangedEvent> _controller =
      StreamController<TournamentStatusChangedEvent>.broadcast();

  Stream<TournamentStatusChangedEvent> get events => _controller.stream;

  StompClient? _client;
  bool _connecting = false;
  final Set<String> _subscribedTournamentIds = <String>{};
  final Map<String, StompUnsubscribe> _unsubscribeByTournamentId =
      <String, StompUnsubscribe>{};

  Future<void> connect() async {
    if (!_enabled) return;
    if (_client != null || _connecting) return;
    _connecting = true;

    try {
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final wsUrl = _wsUrl;
      _client = StompClient(
        config: StompConfig.sockJS(
          url: wsUrl,
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
          reconnectDelay: const Duration(seconds: 5),
          onConnect: _onConnect,
        ),
      );
      _client?.activate();
    } finally {
      _connecting = false;
    }
  }

  void disconnect() {
    if (!_enabled) {
      _client = null;
      _unsubscribeByTournamentId.clear();
      return;
    }
    for (final unsubscribe in _unsubscribeByTournamentId.values) {
      unsubscribe();
    }
    _unsubscribeByTournamentId.clear();
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }

  String get _wsUrl {
    final fromEnv = dotenv.env['WS_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    final base = ApiService().baseUrl.trim();
    return '$base/ws';
  }

  String _topicForTournamentId(String tournamentId) {
    final template = dotenv.env['TOURNAMENT_STATUS_TOPIC_TEMPLATE']?.trim();
    if (template != null && template.isNotEmpty) {
      return template.replaceAll('{id}', tournamentId);
    }

    final prefix = dotenv.env['TOURNAMENT_STATUS_TOPIC_PREFIX']?.trim();
    final topicPrefix = (prefix != null && prefix.isNotEmpty)
        ? prefix
        : '/topic/tournaments';
    return '$topicPrefix/$tournamentId/status';
  }

  void _onConnect(StompFrame frame) {
    _resubscribeAll();
  }

  void syncTournamentIds(Iterable<String> ids) {
    if (!_enabled) return;
    final normalized = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final removed = _subscribedTournamentIds.difference(normalized);
    final added = normalized.difference(_subscribedTournamentIds);

    for (final id in removed) {
      final unsubscribe = _unsubscribeByTournamentId.remove(id);
      unsubscribe?.call();
      _subscribedTournamentIds.remove(id);
    }
    for (final id in added) {
      _subscribedTournamentIds.add(id);
      _subscribeTournament(id);
    }
  }

  void _resubscribeAll() {
    for (final unsubscribe in _unsubscribeByTournamentId.values) {
      unsubscribe();
    }
    _unsubscribeByTournamentId.clear();
    for (final id in _subscribedTournamentIds) {
      _subscribeTournament(id);
    }
  }

  void _subscribeTournament(String tournamentId) {
    final client = _client;
    if (client == null) return;
    final destination = _topicForTournamentId(tournamentId);

    try {
      final unsubscribe = client.subscribe(
        destination: destination,
        callback: (message) => _handleMessage(message.body, tournamentId),
      );
      _unsubscribeByTournamentId[tournamentId] = unsubscribe;
    } catch (_) {}
  }

  void _handleMessage(String? body, String fallbackTournamentId) {
    if (body == null || body.isEmpty) return;

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return;

      final tournamentId =
          decoded['tournamentId']?.toString().trim() ?? fallbackTournamentId;
      if (tournamentId.isEmpty) return;

      _controller.add(
        TournamentStatusChangedEvent(
          tournamentId: tournamentId,
          oldStatus: decoded['oldStatus']?.toString(),
          newStatus: decoded['newStatus']?.toString(),
          changedAt: DateTime.tryParse(decoded['changedAt']?.toString() ?? ''),
          sequence: _parseInt(decoded['sequence']),
        ),
      );
    } catch (_) {}
  }

  int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
