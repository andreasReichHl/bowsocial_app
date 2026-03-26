class TournamentDetails {
  TournamentDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.passesTotal,
    required this.arrowsPerPass,
    required this.targetFace,
    required this.status,
    required this.hostShoots,
    required this.participants,
  });

  final String id;
  final String name;
  final String description;
  final String location;
  final int? passesTotal;
  final int? arrowsPerPass;
  final String targetFace;
  final String status;
  final bool hostShoots;
  final List<TournamentParticipantDetails> participants;

  factory TournamentDetails.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'];
    return TournamentDetails(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      passesTotal: _parseInt(json['passesTotal']),
      arrowsPerPass: _parseInt(json['arrowsPerPass']),
      targetFace: json['targetFace']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      hostShoots: json['hostShoots'] == true,
      participants: rawParticipants is List
          ? rawParticipants
                .whereType<Map<String, dynamic>>()
                .map(TournamentParticipantDetails.fromJson)
                .toList(growable: false)
          : const <TournamentParticipantDetails>[],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class TournamentParticipantDetails {
  TournamentParticipantDetails({
    required this.participantId,
    required this.tournamentId,
    required this.appUserId,
    required this.displayName,
    required this.targetNo,
    required this.targetFace,
    required this.passes,
  });

  final String participantId;
  final String tournamentId;
  final String appUserId;
  final String displayName;
  final int? targetNo;
  final String targetFace;
  final List<TournamentPassDetails> passes;

  factory TournamentParticipantDetails.fromJson(Map<String, dynamic> json) {
    final rawPasses = json['passen'];
    return TournamentParticipantDetails(
      participantId: json['participantId']?.toString() ?? '',
      tournamentId: json['tournamentId']?.toString() ?? '',
      appUserId: json['appUserId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      targetNo: TournamentDetails._parseInt(json['targetNo']),
      targetFace: json['targetFace']?.toString() ?? '',
      passes: rawPasses is List
          ? rawPasses
                .whereType<Map<String, dynamic>>()
                .map(TournamentPassDetails.fromJson)
                .toList(growable: false)
          : const <TournamentPassDetails>[],
    );
  }
}

class TournamentPassDetails {
  TournamentPassDetails({
    required this.id,
    required this.arrows,
    required this.passNo,
  });

  final String id;
  final List<String> arrows;
  final int? passNo;

  factory TournamentPassDetails.fromJson(Map<String, dynamic> json) {
    final rawArrows = json['arrows'];
    return TournamentPassDetails(
      id: json['id']?.toString() ?? '',
      arrows: rawArrows is List
          ? rawArrows.map((arrow) => arrow?.toString() ?? '').toList(growable: false)
          : const <String>[],
      passNo: TournamentDetails._parseInt(json['passNo']),
    );
  }
}
