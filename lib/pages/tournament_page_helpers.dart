import 'dart:math';

import 'package:bowsocial_app/models/tournament_list_item.dart';
import 'package:flutter/material.dart';

bool isActiveTournamentStatus(String status) {
  final s = status.toUpperCase();
  return s == 'DRAFT' || s == 'RUNNING';
}

Color tournamentStatusColor(String status, ColorScheme schema) {
  switch (status.toUpperCase()) {
    case 'RUNNING':
      return schema.surface;
    case 'DRAFT':
      return Colors.grey;
    default:
      return Colors.red;
  }
}

List<TournamentListItem> toTournamentItems(
  List<Map<String, dynamic>> rawItems,
) {
  return rawItems.map(TournamentListItem.fromJson).toList(growable: false);
}

DateTime tournamentGroupDate(TournamentListItem item) {
  final raw = item.startTime ?? item.createdAt ?? DateTime.now();
  return DateTime(raw.year, raw.month, raw.day);
}

String tournamentWeekdayUpper(DateTime date) {
  const weekdays = <String>[
    'MONTAG',
    'DIENSTAG',
    'MITTWOCH',
    'DONNERSTAG',
    'FREITAG',
    'SAMSTAG',
    'SONNTAG',
  ];
  return weekdays[date.weekday - 1];
}

String tournamentFormatDayMonth(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.';
}

String generateTournamentId() {
  final random = Random();
  String hex(int length) =>
      List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-4${hex(3)}-'
      '${(8 + random.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
}

class TournamentDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  TournamentDateHeaderDelegate({
    required this.minExtentHeight,
    required this.maxExtentHeight,
    required this.backgroundColor,
    required this.weekdayText,
    required this.dayMonthText,
    required this.textStyleLeft,
    required this.textStyleRight,
  });

  final double minExtentHeight;
  final double maxExtentHeight;
  final Color backgroundColor;
  final String weekdayText;
  final String dayMonthText;
  final TextStyle? textStyleLeft;
  final TextStyle? textStyleRight;

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: maxExtentHeight,
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        children: [
          Text(weekdayText, style: textStyleLeft),
          const Spacer(),
          Text(dayMonthText, style: textStyleRight),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant TournamentDateHeaderDelegate oldDelegate) {
    return minExtentHeight != oldDelegate.minExtentHeight ||
        maxExtentHeight != oldDelegate.maxExtentHeight ||
        backgroundColor != oldDelegate.backgroundColor ||
        weekdayText != oldDelegate.weekdayText ||
        dayMonthText != oldDelegate.dayMonthText ||
        textStyleLeft != oldDelegate.textStyleLeft ||
        textStyleRight != oldDelegate.textStyleRight;
  }
}
