import 'package:bowsocial_app/models/tournament_details.dart';

class TournamentParticipantScoreSummary {
  const TournamentParticipantScoreSummary({
    required this.totalScore,
    required this.arrowsShot,
    required this.passCount,
    required this.tens,
    required this.misses,
  });

  final int totalScore;
  final int arrowsShot;
  final int passCount;
  final int tens;
  final int misses;
}

TournamentParticipantScoreSummary summarizeParticipantScore(
  TournamentParticipantDetails participant,
) {
  var totalScore = 0;
  var arrowsShot = 0;
  var tens = 0;
  var misses = 0;

  for (final pass in participant.passes) {
    for (final arrow in pass.arrows) {
      final score = _parseArrowScore(arrow);
      if (score == null) continue;
      arrowsShot += 1;
      totalScore += score;
      if (score == 10) tens += 1;
      if (score == 0) misses += 1;
    }
  }

  return TournamentParticipantScoreSummary(
    totalScore: totalScore,
    arrowsShot: arrowsShot,
    passCount: participant.passes.length,
    tens: tens,
    misses: misses,
  );
}

int summarizePassScore(TournamentPassDetails pass) {
  var totalScore = 0;
  for (final arrow in pass.arrows) {
    totalScore += _parseArrowScore(arrow) ?? 0;
  }
  return totalScore;
}

int compareParticipantsByScore(
  TournamentParticipantDetails a,
  TournamentParticipantDetails b,
) {
  final summaryA = summarizeParticipantScore(a);
  final summaryB = summarizeParticipantScore(b);

  final scoreCompare = summaryB.totalScore.compareTo(summaryA.totalScore);
  if (scoreCompare != 0) return scoreCompare;

  final tensCompare = summaryB.tens.compareTo(summaryA.tens);
  if (tensCompare != 0) return tensCompare;

  final missesCompare = summaryA.misses.compareTo(summaryB.misses);
  if (missesCompare != 0) return missesCompare;

  return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
}

int? _parseArrowScore(String rawValue) {
  final normalized = rawValue.trim().toUpperCase();
  if (normalized.isEmpty) return null;
  if (normalized == 'X') return 10;
  if (normalized == 'M' || normalized == 'MISS' || normalized == '-') return 0;

  final digits = RegExp(r'\d+').firstMatch(normalized)?.group(0);
  final parsed = int.tryParse(digits ?? normalized);
  if (parsed == null) return null;
  if (parsed < 0) return 0;
  if (parsed > 10) return 10;
  return parsed;
}
