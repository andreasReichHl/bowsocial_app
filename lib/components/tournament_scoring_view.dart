import 'dart:async';

import 'package:bowsocial_app/models/tournament_details.dart';
import 'package:bowsocial_app/models/tournament_score_summary.dart';
import 'package:flutter/material.dart';

class TournamentScoringView extends StatefulWidget {
  const TournamentScoringView({
    super.key,
    required this.details,
    required this.tournamentName,
    this.fallbackParticipantCount,
    this.fallbackPassesTotal,
    this.fallbackArrowsPerPass,
    this.savingPass = false,
    this.onPassSubmit,
    this.onParticipantTap,
  });

  final TournamentDetails? details;
  final String tournamentName;
  final int? fallbackParticipantCount;
  final int? fallbackPassesTotal;
  final int? fallbackArrowsPerPass;
  final bool savingPass;
  final Future<bool> Function({
    required String passId,
    required List<String> arrows,
  })? onPassSubmit;
  final ValueChanged<TournamentParticipantDetails>? onParticipantTap;

  @override
  State<TournamentScoringView> createState() => _TournamentScoringViewState();
}

class _TournamentScoringViewState extends State<TournamentScoringView> {
  int _selectedPassNo = 1;
  int? _expandedParticipantIndex;
  final Map<String, List<String>> _editedArrowsByParticipantPass =
      <String, List<String>>{};
  final Set<String> _submittingPassIds = <String>{};
  final ScrollController _passChipsScrollController = ScrollController();
  bool _hasUserSelectedPass = false;
  bool _shouldAutoAdvancePassSelection = false;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSelectedPassWithProgress();
    });
  }

  @override
  void didUpdateWidget(covariant TournamentScoringView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedPassWithProgress();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _passChipsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final passesTotal = widget.details?.passesTotal ?? widget.fallbackPassesTotal ?? 0;
    final participantCount =
        widget.details?.participants.length ?? widget.fallbackParticipantCount ?? 0;
    final participants = widget.details?.participants ?? const <TournamentParticipantDetails>[];
    final visibleParticipants = _expandedParticipantIndex == null
        ? participants
        : (_expandedParticipantIndex! >= 0 &&
                _expandedParticipantIndex! < participants.length)
            ? <TournamentParticipantDetails>[participants[_expandedParticipantIndex!]]
            : participants;
    final availablePasses = passesTotal > 0 ? passesTotal : 1;
    final currentPassNo = _resolveCurrentPassNo(participants, availablePasses);
    if (!_hasUserSelectedPass && _selectedPassNo != currentPassNo) {
      _selectedPassNo = currentPassNo.clamp(1, availablePasses);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToPassChip(_selectedPassNo);
      });
    }
    final selectedPassNo = _resolveSelectedPassNo(currentPassNo, availablePasses);
    final chipBackground = theme.brightness == Brightness.light
        ? Color.alphaBlend(
            Colors.white.withAlpha(120),
            theme.scaffoldBackgroundColor,
          )
        : Color.alphaBlend(
            Colors.white.withAlpha(18),
            theme.scaffoldBackgroundColor,
          );
    final cardBackground = theme.brightness == Brightness.light
        ? Color.alphaBlend(
            Colors.white.withAlpha(120),
            theme.scaffoldBackgroundColor,
          )
        : Color.alphaBlend(
            Colors.white.withAlpha(18),
            theme.scaffoldBackgroundColor,
          );

    return Column(
      children: [
        Container(
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 14, 20, 10),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              controller: _passChipsScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: availablePasses,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final passNo = index + 1;
                final isSelected = passNo == selectedPassNo;
                final isDisabled = passNo > currentPassNo;
                return _PassSelectorChip(
                  label: '$passNo/$availablePasses',
                  selected: isSelected,
                  isCurrent: passNo == currentPassNo,
                  disabled: isDisabled,
                  backgroundColor: chipBackground,
                  onTap: isDisabled
                      ? null
                      : () => _handlePassSelection(passNo),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: participants.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      participantCount == 0
                          ? 'Noch keine Teilnehmer vorhanden.'
                          : 'Noch keine Wertungsdaten vorhanden.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: schema.secondary,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  itemCount: visibleParticipants.length,
                  itemBuilder: (context, index) {
                    final participant = visibleParticipants[index];
                    final originalIndex = _expandedParticipantIndex == null
                        ? index
                        : _expandedParticipantIndex!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ParticipantScoreCard(
                        participant: participant,
                        selectedPassNo: selectedPassNo,
                        currentPassNo: currentPassNo,
                        passesTotal: availablePasses,
                        arrowsPerPass: widget.details?.arrowsPerPass ??
                            widget.fallbackArrowsPerPass ??
                            0,
                        backgroundColor: cardBackground,
                        expanded: _expandedParticipantIndex == originalIndex,
                        resolveArrows: (passNo, fallbackArrows) =>
                            _resolveArrowsForParticipantPass(
                              participantIndex: originalIndex,
                              passNo: passNo,
                              fallbackArrows: fallbackArrows,
                            ),
                        onTap: () => _handleParticipantTap(originalIndex),
                      ),
                    );
                  },
                ),
        ),
        if (_expandedParticipantIndex != null)
          _ScoreKeyboard(
            backgroundColor: cardBackground,
            enabled: !widget.savingPass,
            onValueTap: _appendArrowValue,
            onDeleteTap: _removeLastArrowValue,
          ),
      ],
    );
  }

  String _participantPassKey({
    required int participantIndex,
    required int passNo,
  }) {
    return '$participantIndex:$passNo';
  }

  int _resolveSelectedPassNo(int currentPassNo, int availablePasses) {
    final clampedSelectedPassNo = _selectedPassNo.clamp(1, availablePasses);
    if (clampedSelectedPassNo != _selectedPassNo) {
      _selectedPassNo = clampedSelectedPassNo;
    }
    return clampedSelectedPassNo;
  }

  void _syncSelectedPassWithProgress() {
    final participants = widget.details?.participants ?? const <TournamentParticipantDetails>[];
    final availablePasses =
        (widget.details?.passesTotal ?? widget.fallbackPassesTotal ?? 0) > 0
        ? (widget.details?.passesTotal ?? widget.fallbackPassesTotal ?? 0)
        : 1;
    final currentPassNo = _resolveCurrentPassNo(participants, availablePasses);

    if (!_hasUserSelectedPass) {
      _selectedPassNo = currentPassNo.clamp(1, availablePasses);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPassChip(_selectedPassNo);
      });
      return;
    }

    if (!_shouldAutoAdvancePassSelection) return;
    if (currentPassNo <= _selectedPassNo) return;

    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _selectedPassNo = currentPassNo.clamp(1, availablePasses);
        _shouldAutoAdvancePassSelection = false;
      });
      _scrollToPassChip(_selectedPassNo);
    });
  }

  List<String> _resolveArrowsForParticipantPass({
    required int participantIndex,
    required int passNo,
    required List<String> fallbackArrows,
  }) {
    final key = _participantPassKey(
      participantIndex: participantIndex,
      passNo: passNo,
    );
    final edited = _editedArrowsByParticipantPass[key];
    if (edited != null) return edited;
    return List<String>.from(fallbackArrows, growable: false);
  }

  void _appendArrowValue(String value) {
    final participantIndex = _expandedParticipantIndex;
    if (participantIndex == null) return;
    final participants =
        widget.details?.participants ?? const <TournamentParticipantDetails>[];
    if (participantIndex < 0 || participantIndex >= participants.length) return;

    final participant = participants[participantIndex];
    final key = _participantPassKey(
      participantIndex: participantIndex,
      passNo: _selectedPassNo,
    );
    final current = _resolveArrowsForParticipantPass(
      participantIndex: participantIndex,
      passNo: _selectedPassNo,
      fallbackArrows: _fallbackArrowsForPass(participant, _selectedPassNo),
    );
    final passId = _passIdForParticipantPass(participant, _selectedPassNo);
    if (passId == null || passId.isEmpty || _submittingPassIds.contains(passId)) {
      return;
    }
    final arrowsPerPass =
        widget.details?.arrowsPerPass ?? widget.fallbackArrowsPerPass ?? 0;
    final next = [...current];
    final replaceIndex = next.indexWhere(_isEditablePlaceholderArrow);

    if (replaceIndex >= 0) {
      next[replaceIndex] = value;
    } else {
      if (arrowsPerPass > 0 && next.length >= arrowsPerPass) return;
      next.add(value);
    }

    setState(() {
      _editedArrowsByParticipantPass[key] = next;
      if (_isPassComplete(next, arrowsPerPass)) {
        _expandedParticipantIndex = null;
        _submittingPassIds.add(passId);
      }
    });

    if (_isPassComplete(next, arrowsPerPass)) {
      _submitCompletedPass(
        passId: passId,
        participantIndex: participantIndex,
        passNo: _selectedPassNo,
        arrows: _normalizeArrowsForSubmission(next, arrowsPerPass),
      );
    }
  }

  void _removeLastArrowValue() {
    final participantIndex = _expandedParticipantIndex;
    if (participantIndex == null) return;
    final participants =
        widget.details?.participants ?? const <TournamentParticipantDetails>[];
    if (participantIndex < 0 || participantIndex >= participants.length) return;

    final participant = participants[participantIndex];
    final key = _participantPassKey(
      participantIndex: participantIndex,
      passNo: _selectedPassNo,
    );
    final current = _resolveArrowsForParticipantPass(
      participantIndex: participantIndex,
      passNo: _selectedPassNo,
      fallbackArrows: _fallbackArrowsForPass(participant, _selectedPassNo),
    );
    final removeIndex = current.lastIndexWhere(
      (arrow) => !_isEditablePlaceholderArrow(arrow),
    );
    if (removeIndex < 0) return;

    final fallbackArrows = _fallbackArrowsForPass(participant, _selectedPassNo);
    final next = [...current];
    if (removeIndex < fallbackArrows.length) {
      next[removeIndex] = '0';
    } else {
      next.removeAt(removeIndex);
    }
    setState(() {
      if (_matchesArrowList(next, fallbackArrows)) {
        _editedArrowsByParticipantPass.remove(key);
      } else {
        _editedArrowsByParticipantPass[key] = next;
      }
    });
  }

  List<String> _fallbackArrowsForPass(
    TournamentParticipantDetails participant,
    int passNo,
  ) {
    for (final pass in participant.passes) {
      if (pass.passNo == passNo) {
        return List<String>.from(pass.arrows, growable: false);
      }
    }
    return const <String>[];
  }

  String? _passIdForParticipantPass(
    TournamentParticipantDetails participant,
    int passNo,
  ) {
    for (final pass in participant.passes) {
      if (pass.passNo == passNo) return pass.id;
    }
    return null;
  }

  bool _isEditablePlaceholderArrow(String arrow) {
    final normalized = arrow.trim().toUpperCase();
    return normalized.isEmpty || normalized == '0';
  }

  bool _matchesArrowList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  bool _isPassComplete(List<String> arrows, int arrowsPerPass) {
    if (arrowsPerPass <= 0) return false;
    if (arrows.length < arrowsPerPass) return false;
    return arrows.take(arrowsPerPass).every(
      (arrow) => !_isEditablePlaceholderArrow(arrow),
    );
  }

  List<String> _normalizeArrowsForSubmission(List<String> arrows, int arrowsPerPass) {
    final normalized = <String>[
      ...arrows.take(arrowsPerPass > 0 ? arrowsPerPass : arrows.length),
    ];
    final targetLength = arrowsPerPass > 0 ? arrowsPerPass : normalized.length;
    while (normalized.length < targetLength) {
      normalized.add('0');
    }
    return normalized
        .map((arrow) => _isEditablePlaceholderArrow(arrow) ? '0' : arrow)
        .toList(growable: false);
  }

  Future<void> _handlePassSelection(int passNo) async {
    await _persistExpandedParticipantPass();
    if (!mounted) return;
    setState(() {
      _selectedPassNo = passNo;
      _expandedParticipantIndex = null;
      _hasUserSelectedPass = true;
      _shouldAutoAdvancePassSelection = false;
    });
    _scrollToPassChip(passNo);
  }

  Future<void> _handleParticipantTap(int participantIndex) async {
    final isClosingCurrent = _expandedParticipantIndex == participantIndex;
    if (_expandedParticipantIndex != null) {
      await _persistExpandedParticipantPass();
      if (!mounted) return;
    }

    setState(() {
      _expandedParticipantIndex = isClosingCurrent ? null : participantIndex;
    });
  }

  Future<void> _persistExpandedParticipantPass() async {
    final participantIndex = _expandedParticipantIndex;
    if (participantIndex == null) return;
    final participants =
        widget.details?.participants ?? const <TournamentParticipantDetails>[];
    if (participantIndex < 0 || participantIndex >= participants.length) return;

    final participant = participants[participantIndex];
    final passId = _passIdForParticipantPass(participant, _selectedPassNo);
    if (passId == null || passId.isEmpty || _submittingPassIds.contains(passId)) {
      return;
    }

    final key = _participantPassKey(
      participantIndex: participantIndex,
      passNo: _selectedPassNo,
    );
    final fallbackArrows = _fallbackArrowsForPass(participant, _selectedPassNo);
    final current = _resolveArrowsForParticipantPass(
      participantIndex: participantIndex,
      passNo: _selectedPassNo,
      fallbackArrows: fallbackArrows,
    );
    if (_matchesArrowList(current, fallbackArrows)) return;

    final arrowsPerPass =
        widget.details?.arrowsPerPass ?? widget.fallbackArrowsPerPass ?? 0;
    final submissionArrows = _normalizeArrowsForSubmission(current, arrowsPerPass);

    setState(() {
      _submittingPassIds.add(passId);
    });

    try {
      final success = await (widget.onPassSubmit?.call(
            passId: passId,
            arrows: submissionArrows,
          ) ??
          Future<bool>.value(false));
      if (!mounted) return;
      setState(() {
        if (success) {
          _editedArrowsByParticipantPass.remove(key);
        }
        _submittingPassIds.remove(passId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submittingPassIds.remove(passId);
      });
    }
  }

  Future<void> _submitCompletedPass({
    required String passId,
    required int participantIndex,
    required int passNo,
    required List<String> arrows,
  }) async {
    final submit = widget.onPassSubmit;
    if (submit == null) {
      if (!mounted) return;
      setState(() {
        _submittingPassIds.remove(passId);
      });
      return;
    }

    try {
      final success = await submit(passId: passId, arrows: arrows);
      if (!mounted) return;
      setState(() {
        if (success) {
          _editedArrowsByParticipantPass.remove(
            _participantPassKey(participantIndex: participantIndex, passNo: passNo),
          );
          _hasUserSelectedPass = false;
          _shouldAutoAdvancePassSelection = true;
        }
        _submittingPassIds.remove(passId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submittingPassIds.remove(passId);
      });
    }
  }

  int _resolveCurrentPassNo(
    List<TournamentParticipantDetails> participants,
    int availablePasses,
  ) {
    if (participants.isEmpty) return 1;
    var lastCompletedPassNo = 0;

    for (var passNo = 1; passNo <= availablePasses; passNo++) {
      final isPassCompleteForAllParticipants = participants.every((participant) {
        final pass = _findPassForParticipant(participant, passNo);
        if (pass == null) return false;

        final arrows = _resolveArrowsForParticipantPass(
          participantIndex: participants.indexOf(participant),
          passNo: passNo,
          fallbackArrows: pass.arrows,
        );
        final arrowsPerPass =
            widget.details?.arrowsPerPass ?? widget.fallbackArrowsPerPass ?? 0;

        return _isPassComplete(arrows, arrowsPerPass);
      });

      if (!isPassCompleteForAllParticipants) break;
      lastCompletedPassNo = passNo;
    }

    if (lastCompletedPassNo == 0) return 1;
    if (lastCompletedPassNo >= availablePasses) return availablePasses;
    return lastCompletedPassNo + 1;
  }

  TournamentPassDetails? _findPassForParticipant(
    TournamentParticipantDetails participant,
    int passNo,
  ) {
    for (final pass in participant.passes) {
      if (pass.passNo == passNo) return pass;
    }
    return null;
  }

  void _scrollToPassChip(int passNo) {
    if (!_passChipsScrollController.hasClients) return;
    const chipWidth = 94.0;
    final targetOffset = ((passNo - 1) * chipWidth) - 32;
    final maxOffset = _passChipsScrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxOffset);
    _passChipsScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

class _PassSelectorChip extends StatelessWidget {
  const _PassSelectorChip({
    required this.label,
    required this.selected,
    required this.isCurrent,
    required this.disabled,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isCurrent;
  final bool disabled;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  color: disabled
                      ? backgroundColor.withAlpha(130)
                      : backgroundColor,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: disabled
                        ? schema.primary.withAlpha(10)
                        : selected
                        ? schema.secondary.withAlpha(85)
                        : schema.primary.withAlpha(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: disabled
                          ? schema.secondary.withAlpha(90)
                          : schema.secondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (isCurrent)
                const Positioned(
                  right: 2,
                  bottom: 2,
                  child: _CurrentPassDot(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPassDot extends StatelessWidget {
  const _CurrentPassDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFF58A55C),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 1.0,
        ),
      ),
    );
  }
}

class _ParticipantScoreCard extends StatelessWidget {
  const _ParticipantScoreCard({
    required this.participant,
    required this.selectedPassNo,
    required this.currentPassNo,
    required this.arrowsPerPass,
    required this.passesTotal,
    required this.backgroundColor,
    required this.expanded,
    required this.resolveArrows,
    this.onTap,
  });

  final TournamentParticipantDetails participant;
  final int selectedPassNo;
  final int currentPassNo;
  final int arrowsPerPass;
  final int passesTotal;
  final Color backgroundColor;
  final bool expanded;
  final List<String> Function(int passNo, List<String> fallbackArrows) resolveArrows;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final normalizedPasses = _buildNormalizedPasses();
    final selectedPass = normalizedPasses.firstWhere(
      (pass) => pass.passNo == selectedPassNo,
      orElse: () => TournamentPassDetails(
        id: '',
        arrows: resolveArrows(selectedPassNo, const <String>[]),
        passNo: selectedPassNo,
      ),
    );
    final passesUntilSelected = normalizedPasses
        .where((pass) => (pass.passNo ?? 0) <= selectedPassNo)
        .toList(growable: false);
    final cumulativeScore = passesUntilSelected.fold<int>(
      0,
      (total, pass) => total + summarizePassScore(pass),
    );
    final cumulativeArrowsShot = passesUntilSelected.fold<int>(
      0,
      (total, pass) => total + pass.arrows.where((arrow) => arrow.trim().isNotEmpty && arrow.trim() != '0').length,
    );
    final completedPassesUntilSelected = passesUntilSelected
        .where((pass) => _isPassCompleteForTrend(pass.arrows))
        .toList(growable: false);
    final effectiveTrendPassNo = _resolveEffectiveTrendPassNo(passesUntilSelected);
    final passesUntilTrend = normalizedPasses
        .where((pass) => (pass.passNo ?? 0) <= effectiveTrendPassNo)
        .toList(growable: false);
    final completedPassesUntilTrend = passesUntilTrend
        .where((pass) => _isPassCompleteForTrend(pass.arrows))
        .toList(growable: false);
    final passesUntilTrendPrevious = normalizedPasses
        .where((pass) => (pass.passNo ?? 0) <= effectiveTrendPassNo - 1)
        .toList(growable: false);
    final completedPassesUntilTrendPrevious = passesUntilTrendPrevious
        .where((pass) => _isPassCompleteForTrend(pass.arrows))
        .toList(growable: false);
    final trendCumulativeScore = passesUntilTrend.fold<int>(
      0,
      (total, pass) => total + summarizePassScore(pass),
    );
    final trendCumulativeArrowsShot = passesUntilTrend.fold<int>(
      0,
      (total, pass) => total + pass.arrows.where((arrow) => arrow.trim().isNotEmpty && arrow.trim() != '0').length,
    );
    final previousCumulativeScore = passesUntilTrendPrevious.fold<int>(
      0,
      (total, pass) => total + summarizePassScore(pass),
    );
    final previousCumulativeArrowsShot = passesUntilTrendPrevious.fold<int>(
      0,
      (total, pass) => total + pass.arrows.where((arrow) => arrow.trim().isNotEmpty && arrow.trim() != '0').length,
    );
    final average = cumulativeArrowsShot == 0 ? 0.0 : cumulativeScore / cumulativeArrowsShot;
    final passAverage = completedPassesUntilSelected.isEmpty
        ? 0.0
        : cumulativeScore / completedPassesUntilSelected.length;
    final trendAverage = trendCumulativeArrowsShot == 0
        ? null
        : trendCumulativeScore / trendCumulativeArrowsShot;
    final trendPassAverage = completedPassesUntilTrend.isEmpty
        ? null
        : trendCumulativeScore / completedPassesUntilTrend.length;
    final previousAverage = previousCumulativeArrowsShot == 0
        ? null
        : previousCumulativeScore / previousCumulativeArrowsShot;
    final previousPassAverage = completedPassesUntilTrendPrevious.isEmpty
        ? null
        : previousCumulativeScore / completedPassesUntilTrendPrevious.length;
    final maxArrowCount = arrowsPerPass > 0 && passesTotal > 0
        ? passesTotal * arrowsPerPass
        : cumulativeArrowsShot;
    final trend = _passTrendFromAverages(
      current: trendAverage,
      previous: previousAverage,
    );
    final passTrend = _passTrendFromAverages(
      current: trendPassAverage,
      previous: previousPassAverage,
    );
    final visiblePasses = [...normalizedPasses]
      ..sort((a, b) => (a.passNo ?? 0).compareTo(b.passNo ?? 0));
    final completedPasses = visiblePasses
        .where((pass) => (pass.passNo ?? 0) <= selectedPassNo)
        .toList(growable: false);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: schema.primary.withAlpha(28)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: schema.primary.withAlpha(22)),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 18,
                        color: schema.secondary.withAlpha(150),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 28,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            participant.displayName.isEmpty
                                ? 'Unbekannter Teilnehmer'
                                : participant.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: schema.secondary,
                            fontWeight: FontWeight.w400,
                            fontSize: 19,
                            height: 1.0,
                          ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 36,
                    height: 20,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$cumulativeScore',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: schema.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 21,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -3),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      _AverageStat(
                        label: 'Ø',
                        value: average.toStringAsFixed(1),
                        trend: trend,
                      ),
                      _AverageStat(
                        label: '|',
                        value: passAverage.toStringAsFixed(1),
                        trend: passTrend,
                        spacing: 2,
                      ),
                      const _TextStat(value: '|'),
                      _TextStat(
                        value: '$cumulativeArrowsShot/$maxArrowCount',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Divider(height: 1, color: schema.primary.withAlpha(24)),
              const SizedBox(height: 10),
              if (expanded)
                _ExpandedPassList(
                  passes: completedPasses,
                  selectedPassNo: selectedPassNo,
                  arrowsPerPass: arrowsPerPass,
                )
              else
                _PassScoreRow(
                  pass: selectedPass,
                  currentPassNo: currentPassNo,
                  arrowsPerPass: arrowsPerPass,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<TournamentPassDetails> _buildNormalizedPasses() {
    final passesByNo = <int, TournamentPassDetails>{};
    for (final pass in participant.passes) {
      final passNo = pass.passNo;
      if (passNo == null) continue;
      passesByNo[passNo] = TournamentPassDetails(
        id: pass.id,
        arrows: resolveArrows(passNo, pass.arrows),
        passNo: passNo,
      );
    }

    final highestPassNo = [
      currentPassNo,
      selectedPassNo,
      ...passesByNo.keys,
    ].fold<int>(1, (maxValue, value) => value > maxValue ? value : maxValue);

    return List<TournamentPassDetails>.generate(highestPassNo, (index) {
      final passNo = index + 1;
      return passesByNo[passNo] ??
          TournamentPassDetails(
            id: '',
            arrows: resolveArrows(passNo, const <String>[]),
            passNo: passNo,
          );
    }, growable: false);
  }

  int _resolveEffectiveTrendPassNo(List<TournamentPassDetails> passesUntilSelected) {
    var effectivePassNo = 0;

    for (final pass in passesUntilSelected) {
      if (_isPassCompleteForTrend(pass.arrows)) {
        effectivePassNo = pass.passNo ?? effectivePassNo;
      }
    }

    if (effectivePassNo > 0) return effectivePassNo;
    return passesUntilSelected.isEmpty ? 0 : (passesUntilSelected.first.passNo ?? 0);
  }

  bool _isPassCompleteForTrend(List<String> arrows) {
    if (arrowsPerPass <= 0) return false;
    if (arrows.length < arrowsPerPass) return false;
    return arrows.take(arrowsPerPass).every((arrow) {
      final normalized = arrow.trim().toUpperCase();
      return normalized.isNotEmpty && normalized != '0';
    });
  }

}

class _ExpandedPassList extends StatelessWidget {
  const _ExpandedPassList({
    required this.passes,
    required this.selectedPassNo,
    required this.arrowsPerPass,
  });

  final List<TournamentPassDetails> passes;
  final int selectedPassNo;
  final int arrowsPerPass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    if (passes.isEmpty) {
      return Text(
        'Noch keine Passen erfasst.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: schema.secondary.withAlpha(150),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < passes.length; index++) ...[
          _ExpandedPassRow(
            pass: passes[index],
            selectedPassNo: selectedPassNo,
            arrowsPerPass: arrowsPerPass,
          ),
          if (index < passes.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AverageStat extends StatelessWidget {
  const _AverageStat({
    required this.label,
    required this.value,
    required this.trend,
    this.spacing = 4,
  });

  final String label;
  final String value;
  final _PassTrend trend;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label $value',
          style: theme.textTheme.bodySmall?.copyWith(
            color: schema.secondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(width: spacing),
        _PassTrendIndicator(trend: trend),
      ],
    );
  }
}

class _TextStat extends StatelessWidget {
  const _TextStat({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    return Text(
      value,
      style: theme.textTheme.bodySmall?.copyWith(
        color: schema.secondary,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _ExpandedPassRow extends StatelessWidget {
  const _ExpandedPassRow({
    required this.pass,
    required this.selectedPassNo,
    required this.arrowsPerPass,
  });

  final TournamentPassDetails pass;
  final int selectedPassNo;
  final int arrowsPerPass;

  @override
  Widget build(BuildContext context) {
    return _PassScoreRow(
      pass: pass,
      currentPassNo: selectedPassNo,
      arrowsPerPass: arrowsPerPass,
    );
  }
}

class _PassScoreRow extends StatelessWidget {
  const _PassScoreRow({
    required this.pass,
    required this.currentPassNo,
    required this.arrowsPerPass,
  });

  final TournamentPassDetails pass;
  final int currentPassNo;
  final int arrowsPerPass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final isCurrent = pass.passNo == currentPassNo;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          height: 30,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${pass.passNo ?? '-'}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isCurrent
                      ? schema.primary.withAlpha(150)
                      : schema.secondary.withAlpha(110),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildArrowChips(
              pass,
              arrowsPerPass,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          height: 30,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${summarizePassScore(pass)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: schema.secondary,
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildArrowChips(
    TournamentPassDetails pass,
    int arrowsPerPass,
  ) {
    final totalSlots = arrowsPerPass > 0 ? arrowsPerPass : pass.arrows.length;
    final values = [
      ...pass.arrows,
      for (var i = pass.arrows.length; i < totalSlots; i++) '',
    ];
    return values.map((arrow) => _ArrowValueChip(value: arrow)).toList(growable: false);
  }
}

class _ArrowValueChip extends StatelessWidget {
  const _ArrowValueChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final resolvedValue = value.trim();
    final normalized = resolvedValue.toUpperCase();
    final underlineColor = switch (normalized) {
      '10' || 'X' => const Color(0xFFE2B400),
      '9' || '8' => const Color(0xFFD93C32),
      '7' || '6' => const Color(0xFF4D47FF),
      '5' || '4' => const Color(0xFF1A1A1A),
      '3' || '2' || '1' || 'M' || 'MISS' || '-' => const Color(0xFF1A1A1A),
      _ => schema.primary.withAlpha(40),
    };

    return Container(
      width: 36,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Color.alphaBlend(
                Colors.white.withAlpha(120),
                theme.scaffoldBackgroundColor,
              )
            : Color.alphaBlend(
                Colors.white.withAlpha(18),
                theme.scaffoldBackgroundColor,
              ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: schema.primary.withAlpha(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.brightness == Brightness.light ? 10 : 18),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 14,
            child: Center(
              child: Text(
                resolvedValue.isEmpty ? '-' : resolvedValue,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: schema.secondary,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 16,
            height: 2,
            decoration: BoxDecoration(
              color: underlineColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreKeyboard extends StatelessWidget {
  const _ScoreKeyboard({
    required this.backgroundColor,
    required this.enabled,
    required this.onValueTap,
    required this.onDeleteTap,
  });

  final Color backgroundColor;
  final bool enabled;
  final ValueChanged<String> onValueTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    const rows = <List<String>>[
      ['X', '10', '9'],
      ['8', '7', '6'],
      ['5', '4', '3'],
      ['2', '1', 'M'],
    ];

    return SizedBox(
      height: 238,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(color: schema.primary.withAlpha(22)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(theme.brightness == Brightness.light ? 18 : 28),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
                      Expanded(
                        child: Row(
                          children: [
                            for (var columnIndex = 0;
                                columnIndex < rows[rowIndex].length;
                                columnIndex++) ...[
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: columnIndex < rows[rowIndex].length - 1 ? 6 : 0,
                                    bottom: rowIndex < rows.length - 1 ? 6 : 0,
                                  ),
                                  child: _KeyboardKey(
                                    value: rows[rowIndex][columnIndex],
                                    enabled: enabled,
                                    onTap: () => onValueTap(rows[rowIndex][columnIndex]),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 38,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _KeyboardDeleteKey(
                    color: schema.secondary,
                    enabled: enabled,
                    onTap: onDeleteTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyboardKey extends StatelessWidget {
  const _KeyboardKey({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final underlineColor = switch (value) {
      'X' || '10' || '9' => const Color(0xFFE2B400),
      '8' || '7' => const Color(0xFFD93C32),
      '6' || '5' => const Color(0xFF1E8DCE),
      '4' || '3' || '2' || '1' || 'M' => const Color(0xFF1A1A1A),
      _ => schema.primary.withAlpha(40),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: schema.primary.withAlpha(18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(theme.brightness == Brightness.light ? 16 : 26),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: schema.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 42,
                height: 2,
                decoration: BoxDecoration(
                  color: underlineColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyboardDeleteKey extends StatelessWidget {
  const _KeyboardDeleteKey({
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: schema.primary.withAlpha(18)),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 18,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

enum _PassTrend { up, down, same }

_PassTrend _passTrendFromAverages({
  required double? current,
  required double? previous,
}) {
  if (current == null || previous == null) return _PassTrend.same;
  if ((current - previous).abs() < 0.001) return _PassTrend.same;
  return current > previous ? _PassTrend.up : _PassTrend.down;
}

class _PassTrendIndicator extends StatelessWidget {
  const _PassTrendIndicator({required this.trend});

  final _PassTrend trend;

  @override
  Widget build(BuildContext context) {
    switch (trend) {
      case _PassTrend.up:
        return Icon(
          Icons.arrow_upward,
          size: 12,
          color: const Color(0xFF58A55C),
          weight: 400,
        );
      case _PassTrend.down:
        return Icon(
          Icons.arrow_downward,
          size: 12,
          color: const Color(0xFFF04A3A),
          weight: 400,
        );
      case _PassTrend.same:
        return const Icon(
          Icons.remove,
          size: 12,
          color: Color(0xFFE2B400),
          weight: 400,
        );
    }
  }
}
