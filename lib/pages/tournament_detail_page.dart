import 'package:bowsocial_app/components/app_page_header.dart';
import 'package:flutter/material.dart';

class TournamentDetailPage extends StatelessWidget {
  const TournamentDetailPage({
    super.key,
    required this.tournamentName,
  });

  final String tournamentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppPageHeader(
            title: tournamentName.isEmpty ? 'Tournament' : tournamentName,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, color: schema.primary),
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
