import 'package:bowsocial_app/api/api_service.dart';
import 'package:bowsocial_app/components/app_buttons.dart';
import 'package:bowsocial_app/components/tournament_leaderboard_view.dart';
import 'package:bowsocial_app/components/tournament_scoring_view.dart';
import 'package:bowsocial_app/components/app_snackbar.dart';
import 'package:bowsocial_app/components/tournament_page_header.dart';
import 'package:bowsocial_app/components/tournament_view_switch.dart';
import 'package:bowsocial_app/models/tournament_details.dart';
import 'package:bowsocial_app/pages/login_page.dart';
import 'package:flutter/material.dart';

class TournamentDetailPage extends StatefulWidget {
  const TournamentDetailPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentStatus,
    required this.hostUserId,
    this.participantCount,
    this.passesTotal,
    this.arrowsPerPass,
    this.targetFace = '',
    this.location = '',
  });

  final String tournamentId;
  final String tournamentName;
  final String tournamentStatus;
  final String hostUserId;
  final int? participantCount;
  final int? passesTotal;
  final int? arrowsPerPass;
  final String targetFace;
  final String location;

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage> {
  late String _status = widget.tournamentStatus;
  TournamentDetailTab _selectedTab = TournamentDetailTab.scoring;
  bool _starting = false;
  bool _savingPass = false;
  bool _loadingUserId = true;
  bool _loadingDetails = true;
  String? _currentUserId;
  String? _detailsError;
  TournamentDetails? _details;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadTournamentDetails();
  }

  Future<void> _loadCurrentUserId() async {
    String? userId = await TokenStorage.readUserId();
    final token = await TokenStorage.readToken();
    final fromToken = token == null
        ? null
        : TokenStorage.extractUserIdFromJwt(token);
    if (fromToken != null && fromToken.isNotEmpty) {
      userId = fromToken;
      await TokenStorage.saveUserId(fromToken);
    }
    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
      _loadingUserId = false;
    });
  }

  Future<void> _loadTournamentDetails() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      await TokenStorage.clearToken();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    if (mounted) {
      setState(() {
        _loadingDetails = true;
        _detailsError = null;
      });
    }

    try {
      final raw = await ApiService().getTournamentDetails(
        token,
        tournamentId: widget.tournamentId,
        hostUserId: widget.hostUserId,
      );
      if (!mounted) return;
      setState(() {
        _details = TournamentDetails.fromJson(raw);
        _status = _details?.status.isNotEmpty == true
            ? _details!.status
            : _status;
        _loadingDetails = false;
      });
    } catch (e) {
      if (e.toString().contains('AUTH_EXPIRED')) {
        await TokenStorage.clearToken();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _loadingDetails = false;
        _detailsError = 'Tournament-Details konnten nicht geladen werden';
      });
    }
  }

  bool get _isHost {
    final host = widget.hostUserId.trim().toLowerCase();
    final current = (_currentUserId ?? '').trim().toLowerCase();
    if (host.isEmpty || current.isEmpty) return false;
    return host == current;
  }

  Future<void> _startTournament() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      await TokenStorage.clearToken();
      if (!mounted) return;
      AppSnackbar.show(context, 'Bitte erneut einloggen');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    if (mounted) {
      setState(() => _starting = true);
    }
    try {
      await ApiService().updateTournamentStatus(
        token,
        tournamentId: widget.tournamentId,
        status: 'RUNNING',
      );
      if (!mounted) return;
      setState(() {
        _status = 'RUNNING';
      });
      await _loadTournamentDetails();
      if (!mounted) return;
      AppSnackbar.show(context, 'Tournament gestartet');
    } catch (e) {
      if (e.toString().contains('AUTH_EXPIRED')) {
        await TokenStorage.clearToken();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }
      if (!mounted) return;
      AppSnackbar.show(context, 'Starten fehlgeschlagen');
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<bool> _savePassArrows({
    required String passId,
    required List<String> arrows,
  }) async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      await TokenStorage.clearToken();
      if (!mounted) return false;
      AppSnackbar.show(context, 'Bitte erneut einloggen');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return false;
    }

    if (mounted) {
      setState(() => _savingPass = true);
    }

    try {
      await ApiService().updatePassArrows(
        token,
        passId: passId,
        arrows: arrows,
      );
      if (mounted) {
        setState(() {
          _details = _details == null ? null : _withUpdatedPassArrows(_details!, passId, arrows);
        });
      }
      return true;
    } catch (e) {
      if (e.toString().contains('AUTH_EXPIRED')) {
        await TokenStorage.clearToken();
        if (!mounted) return false;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return false;
      }
      if (!mounted) return false;
      AppSnackbar.show(context, 'Passe konnte nicht gespeichert werden');
      return false;
    } finally {
      if (mounted) {
        setState(() => _savingPass = false);
      }
    }
  }

  TournamentDetails _withUpdatedPassArrows(
    TournamentDetails details,
    String passId,
    List<String> arrows,
  ) {
    return TournamentDetails(
      id: details.id,
      name: details.name,
      description: details.description,
      location: details.location,
      passesTotal: details.passesTotal,
      arrowsPerPass: details.arrowsPerPass,
      targetFace: details.targetFace,
      status: details.status,
      hostShoots: details.hostShoots,
      participants: details.participants.map((participant) {
        return TournamentParticipantDetails(
          participantId: participant.participantId,
          tournamentId: participant.tournamentId,
          appUserId: participant.appUserId,
          displayName: participant.displayName,
          targetNo: participant.targetNo,
          targetFace: participant.targetFace,
          passes: participant.passes.map((pass) {
            if (pass.id != passId) return pass;
            return TournamentPassDetails(
              id: pass.id,
              arrows: List<String>.from(arrows, growable: false),
              passNo: pass.passNo,
            );
          }).toList(growable: false),
        );
      }).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navAccent = theme.brightness == Brightness.light
        ? const Color(0xFF6D863E)
        : const Color(0xFF8FB339);
    final isRunning = _status.toUpperCase() == 'RUNNING';
    final details = _details;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          TournamentPageHeader(
            title: widget.tournamentName.isEmpty
                ? 'Tournament'
                : widget.tournamentName,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, color: navAccent),
            ),
            bottom: isRunning
                ? TournamentViewSwitch(
                    selectedTab: _selectedTab,
                    onChanged: (nextTab) {
                      if (!mounted) return;
                      setState(() {
                        _selectedTab = nextTab;
                      });
                    },
                  )
                : null,
          ),
          Expanded(
            child: isRunning
                ? _loadingDetails
                    ? const Center(child: CircularProgressIndicator())
                    : _detailsError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _detailsError!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _loadTournamentDetails,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : (_selectedTab == TournamentDetailTab.scoring
                          ? TournamentScoringView(
                              tournamentName: widget.tournamentName,
                              fallbackParticipantCount: widget.participantCount,
                              fallbackPassesTotal: widget.passesTotal,
                              fallbackArrowsPerPass: widget.arrowsPerPass,
                              details: details,
                              savingPass: _savingPass,
                              onPassSubmit: _savePassArrows,
                            )
                          : TournamentLeaderboardView(
                              details: details,
                              fallbackParticipantCount: widget.participantCount,
                            ))
                : _status.toUpperCase() == 'DRAFT'
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isHost) ...[
                            Text(
                              'Der Host hat das Tournament noch nicht gestartet',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (_isHost && !_loadingUserId) ...[
                            SizedBox(
                              width: double.infinity,
                              child: AppPrimaryButton(
                                label: 'Tournament starten',
                                onPressed: _startTournament,
                                isLoading: _starting,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'Tournament ist nicht aktiv',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
