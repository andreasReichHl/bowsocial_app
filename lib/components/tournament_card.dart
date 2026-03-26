import 'package:bowsocial_app/models/tournament_list_item.dart';
import 'package:bowsocial_app/models/target_face_mapper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class TournamentCard extends StatelessWidget {
  const TournamentCard({
    super.key,
    required this.item,
    required this.offset,
    required this.deleteRevealWidth,
    required this.backgroundColor,
    required this.borderColor,
    required this.nameColor,
    required this.metaColor,
    required this.deleteButtonTextColor,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
    required this.onCardTap,
    required this.onDeleteOrStopPressed,
    required this.canEditTournament,
    required this.onMenuAction,
  });

  final TournamentListItem item;
  final double offset;
  final double deleteRevealWidth;
  final Color backgroundColor;
  final Color borderColor;
  final Color nameColor;
  final Color metaColor;
  final Color deleteButtonTextColor;
  final ValueChanged<DragUpdateDetails> onHorizontalDragUpdate;
  final GestureDragEndCallback onHorizontalDragEnd;
  final VoidCallback onCardTap;
  final VoidCallback onDeleteOrStopPressed;
  final bool canEditTournament;
  final ValueChanged<String> onMenuAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final isRunning = item.status.toUpperCase() == 'RUNNING';
    final menuBg = theme.brightness == Brightness.light
        ? Colors.white
        : Color.alphaBlend(
            Colors.white.withAlpha(14),
            theme.scaffoldBackgroundColor,
          );
    final metaColorMuted = metaColor.withAlpha(158);
    final targetFaceLabel = targetFaceLabelForValue(item.targetFace);
    const borderRadius = BorderRadius.all(Radius.circular(8));

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: borderRadius,
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: deleteRevealWidth - 26,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: deleteButtonTextColor,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onDeleteOrStopPressed,
                  child: Text(
                    isRunning ? 'Stoppen' : 'Löschen',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: deleteButtonTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(offset, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: onHorizontalDragUpdate,
              onHorizontalDragEnd: onHorizontalDragEnd,
              child: Material(
                color: backgroundColor,
                borderRadius: borderRadius,
                child: InkWell(
                  onTap: onCardTap,
                  borderRadius: borderRadius,
                  splashColor: theme.brightness == Brightness.light
                      ? Colors.black.withAlpha(16)
                      : Colors.white.withAlpha(20),
                  highlightColor: theme.brightness == Brightness.light
                      ? Colors.black.withAlpha(8)
                      : Colors.white.withAlpha(10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    decoration: const BoxDecoration(borderRadius: borderRadius),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(width: 0.5),
                          Container(
                            width: 5,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: borderColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 25),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name.isEmpty
                                            ? 'Tournament'
                                            : item.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: nameColor,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 0),
                                      child: PopupMenuButton<String>(
                                        onSelected: onMenuAction,
                                        color: menuBg,
                                        shadowColor: Colors.black.withAlpha(36),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color: schema.primary.withAlpha(28),
                                            width: 0.8,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                          minHeight: 28,
                                        ),
                                        icon: Icon(
                                          Symbols.more_vert,
                                          size: 22,
                                          weight: 500,
                                          color: metaColor,
                                        ),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'key_qr',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.key_rounded,
                                                  size: 18,
                                                  color: schema.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'QR-Code',
                                                  style: TextStyle(
                                                    color: schema.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuDivider(
                                            height: 1,
                                            color: schema.primary.withAlpha(24),
                                          ),
                                          PopupMenuItem(
                                            value: 'participants',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.group_outlined,
                                                  size: 18,
                                                  color: schema.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Teilnehmer',
                                                  style: TextStyle(
                                                    color: schema.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuDivider(
                                            height: 1,
                                            color: schema.primary.withAlpha(32),
                                          ),
                                          PopupMenuItem(
                                            value: 'edit',
                                            enabled: canEditTournament,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: canEditTournament
                                                      ? schema.primary
                                                      : schema.secondary
                                                            .withAlpha(110),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Tournament bearbeiten',
                                                  style: TextStyle(
                                                    color: canEditTournament
                                                        ? schema.secondary
                                                        : schema.secondary
                                                              .withAlpha(110),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isRunning)
                                            PopupMenuItem(
                                              value: 'stop',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.stop_circle_outlined,
                                                    size: 18,
                                                    color: schema.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Stoppen',
                                                    style: TextStyle(
                                                      color: schema.secondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Symbols.target,
                                            size: 17,
                                            weight: 400,
                                            color: metaColorMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            targetFaceLabel.isEmpty
                                                ? '-'
                                                : targetFaceLabel,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: metaColorMuted,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.group_outlined,
                                            size: 16,
                                            color: metaColorMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.participants?.toString() ??
                                                '0',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: metaColorMuted,
                                                  fontSize: 13,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
