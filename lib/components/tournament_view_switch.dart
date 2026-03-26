import 'package:flutter/material.dart';

enum TournamentDetailTab { scoring, leaderboard }

class TournamentViewSwitch extends StatelessWidget {
  const TournamentViewSwitch({
    super.key,
    required this.selectedTab,
    required this.onChanged,
  });

  final TournamentDetailTab selectedTab;
  final ValueChanged<TournamentDetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: _TabLabel(
              label: 'Wertung',
              selected: selectedTab == TournamentDetailTab.scoring,
              onTap: () => onChanged(TournamentDetailTab.scoring),
            ),
          ),
          Expanded(
            child: _TabLabel(
              label: 'Rangliste',
              selected: selectedTab == TournamentDetailTab.leaderboard,
              onTap: () => onChanged(TournamentDetailTab.leaderboard),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final activeColor = schema.secondary;
    final inactiveColor = schema.secondary.withAlpha(110);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? activeColor : inactiveColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 3,
                width: selected ? 132 : 0,
                color: selected ? activeColor : Colors.transparent,
              ),
              const SizedBox(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
