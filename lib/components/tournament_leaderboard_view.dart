import 'package:bowsocial_app/models/tournament_details.dart';
import 'package:bowsocial_app/models/tournament_score_summary.dart';
import 'package:flutter/material.dart';

class TournamentLeaderboardView extends StatelessWidget {
  const TournamentLeaderboardView({
    super.key,
    required this.details,
    this.fallbackParticipantCount,
  });

  final TournamentDetails? details;
  final int? fallbackParticipantCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final participants = [...?details?.participants]..sort(compareParticipantsByScore);
    final participantCount = participants.isNotEmpty
        ? participants.length
        : fallbackParticipantCount ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: schema.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: schema.primary.withAlpha(32)),
          ),
          child: participants.isEmpty
              ? Text(
                  participantCount == 0
                      ? 'Noch keine Teilnehmer in der Rangliste.'
                      : 'Noch keine Score-Daten für die Rangliste vorhanden.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: schema.secondary,
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < participants.length; index++) ...[
                      _LeaderboardRow(
                        rank: index + 1,
                        participant: participants[index],
                      ),
                      if (index < participants.length - 1)
                        Divider(
                          height: 18,
                          color: schema.primary.withAlpha(18),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.participant,
  });

  final int rank;
  final TournamentParticipantDetails participant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final summary = summarizeParticipantScore(participant);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: schema.primary.withAlpha(14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$rank',
            style: theme.textTheme.titleSmall?.copyWith(
              color: schema.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                participant.displayName.isEmpty
                    ? 'Unbekannter Teilnehmer'
                    : participant.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: schema.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Scheibe ${participant.targetNo ?? '-'} • '
                '${summary.passCount} Passen • ${summary.arrowsShot} Pfeile',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: schema.secondary.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${summary.totalScore}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: schema.secondary,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${summary.tens}x 10',
              style: theme.textTheme.bodySmall?.copyWith(
                color: schema.secondary.withAlpha(150),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
