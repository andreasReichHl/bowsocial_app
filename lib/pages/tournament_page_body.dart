import 'package:bowsocial_app/components/tournament_card.dart';
import 'package:bowsocial_app/models/tournament_list_item.dart';
import 'package:bowsocial_app/pages/tournament_page_helpers.dart';
import 'package:flutter/material.dart';

class TournamentPageBody extends StatelessWidget {
  const TournamentPageBody({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.swipeOffsets,
    required this.suppressNextCardTapItemId,
    required this.navIconGreenLight,
    required this.navIconGreenDark,
    required this.deleteRevealWidth,
    required this.onRefresh,
    required this.onRetryLoad,
    required this.onCardDragUpdate,
    required this.onCardDragEnd,
    required this.onCardTap,
    required this.onDeleteOrStopPressed,
    required this.onMenuAction,
  });

  final List<TournamentListItem> items;
  final bool loading;
  final String? error;
  final Map<String, double> swipeOffsets;
  final String? suppressNextCardTapItemId;
  final Color navIconGreenLight;
  final Color navIconGreenDark;
  final double deleteRevealWidth;

  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetryLoad;
  final void Function(TournamentListItem, DragUpdateDetails) onCardDragUpdate;
  final void Function(TournamentListItem) onCardDragEnd;
  final void Function(TournamentListItem, double) onCardTap;
  final Future<void> Function(TournamentListItem) onDeleteOrStopPressed;
  final Future<void> Function(TournamentListItem, String) onMenuAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final nameColor = schema.secondary;
    final metaColor = schema.secondary;
    final navAccent = theme.brightness == Brightness.light
        ? navIconGreenLight
        : navIconGreenDark;
    final chromeBg = theme.brightness == Brightness.light
        ? Color.alphaBlend(
            Colors.white.withAlpha(120),
            theme.scaffoldBackgroundColor,
          )
        : Color.alphaBlend(
            Colors.white.withAlpha(18),
            theme.scaffoldBackgroundColor,
          );

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: schema.secondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetryLoad,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    final activeItems = items.where((item) => isActiveTournamentStatus(item.status)).toList();
    activeItems.sort((a, b) => tournamentGroupDate(b).compareTo(tournamentGroupDate(a)));

    final groupedItems = <DateTime, List<TournamentListItem>>{};
    for (final item in activeItems) {
      final date = tournamentGroupDate(item);
      groupedItems.putIfAbsent(date, () => <TournamentListItem>[]).add(item);
    }
    final groupEntries = groupedItems.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (groupEntries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 96),
            Center(
              child: Text(
                'Keine aktiven Tournament vorhanden',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: schema.secondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              for (final entry in groupEntries) ...[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: TournamentDateHeaderDelegate(
                    minExtentHeight: 34,
                    maxExtentHeight: 34,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    weekdayText: tournamentWeekdayUpper(entry.key),
                    dayMonthText: tournamentFormatDayMonth(entry.key),
                    textStyleLeft: theme.textTheme.titleSmall?.copyWith(
                      color: navAccent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                    textStyleRight: theme.textTheme.titleSmall?.copyWith(
                      color: navAccent,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = entry.value[index];
                      final offset = swipeOffsets[item.id] ?? 0;
                      return TournamentCard(
                        item: item,
                        offset: offset,
                        deleteRevealWidth: deleteRevealWidth,
                        backgroundColor: chromeBg,
                        borderColor: tournamentStatusColor(item.status, schema),
                        nameColor: nameColor,
                        metaColor: metaColor,
                        deleteButtonTextColor: schema.onPrimary,
                        onHorizontalDragUpdate: (details) {
                          onCardDragUpdate(item, details);
                        },
                        onHorizontalDragEnd: (_) {
                          onCardDragEnd(item);
                        },
                        onCardTap: () => onCardTap(item, offset),
                        onDeleteOrStopPressed: () => onDeleteOrStopPressed(item),
                        onMenuAction: (action) => onMenuAction(item, action),
                      );
                    },
                    childCount: entry.value.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ],
    );
  }
}

