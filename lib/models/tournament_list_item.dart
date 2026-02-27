class TournamentListItem {
  final String id;
  final String hostUserId;
  final String name;
  final String description;
  final String location;
  final String status;
  final int? publicKey;
  final int? participants;
  final int? passesTotal;
  final int? arrowsPerPass;
  final String targetFace;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? createdAt;

  TournamentListItem({
    required this.id,
    required this.hostUserId,
    required this.name,
    required this.description,
    required this.location,
    required this.status,
    required this.publicKey,
    required this.participants,
    required this.passesTotal,
    required this.arrowsPerPass,
    required this.targetFace,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  factory TournamentListItem.fromJson(Map<String, dynamic> json) {
    return TournamentListItem(
      id: json['id']?.toString() ?? '',
      hostUserId: json['hostUserId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      publicKey: _parseInt(json['publicKey']),
      participants: _parseInt(json['participants']),
      passesTotal: _parseInt(json['passesTotal']),
      arrowsPerPass: _parseInt(json['arrowsPerPass']),
      targetFace: json['targetFace']?.toString() ?? '',
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      final ms = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
        isUtc: true,
      ).toLocal();
    }
    return DateTime.tryParse(value.toString());
  }
}
