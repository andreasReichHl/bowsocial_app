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
      publicKey: json['publicKey'] is int
          ? json['publicKey'] as int
          : int.tryParse(json['publicKey']?.toString() ?? ''),
      participants: json['participants'] is int
          ? json['participants'] as int
          : int.tryParse(json['participants']?.toString() ?? ''),
      passesTotal: json['passesTotal'] as int?,
      arrowsPerPass: json['arrowsPerPass'] as int?,
      targetFace: json['targetFace']?.toString() ?? '',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
