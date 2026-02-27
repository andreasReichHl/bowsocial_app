import 'package:bowsocial_app/api/api_service.dart';
import 'package:bowsocial_app/components/app_selection_sheet.dart';
import 'package:bowsocial_app/components/app_snackbar.dart';
import 'package:bowsocial_app/components/tournament_create_sheet.dart';
import 'package:bowsocial_app/models/tournament_list_item.dart';
import 'package:bowsocial_app/pages/tournament_page_body.dart';
import 'package:bowsocial_app/pages/tournament_page_helpers.dart';
import 'package:bowsocial_app/pages/login_page.dart';
import 'package:bowsocial_app/pages/tournament_detail_page.dart';
import 'package:bowsocial_app/pages/tournament_participants_page.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TournamentPage extends StatefulWidget {
  const TournamentPage({super.key});

  @override
  State<TournamentPage> createState() => TournamentPageState();
}

class TournamentPageState extends State<TournamentPage> {
  static const Color _navIconGreenLight = Color(0xFF6D863E);
  static const Color _navIconGreenDark = Color(0xFF8FB339);
  static const double _deleteRevealWidth = 112;
  static const String _defaultTournamentName = 'Vereins-Tournament am Freitag';
  static const String _defaultTournamentDescription =
      'Lockeres Trainingstournament über 6 Passen mit 3 Pfeilen.';

  List<TournamentListItem> _items = const [];
  bool _loading = true;
  String? _error;
  bool _hostShoots = true;
  final Map<String, double> _swipeOffsets = {};
  bool _redirectingToLogin = false;
  bool _reloadScheduled = false;
  String? _suppressNextCardTapItemId;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _targetFaceController = TextEditingController();
  int _passesTotal = 6;
  int _arrowsPerPass = 3;
  String? _targetFace;

  final List<Map<String, String>> _targetFaces = const [
    {'value': 'WA_40CM', 'label': '40 cm (WA Indoor)'},
    {'value': 'WA_60CM', 'label': '60 cm (WA)'},
    {'value': 'WA_80CM', 'label': '80 cm (WA)'},
    {'value': 'WA_122CM', 'label': '122 cm (WA Outdoor)'},
    {'value': 'WA_40CM_TRIPLE', 'label': '40 cm Triple Spot (WA Indoor)'},
    {'value': 'WA_60CM_TRIPLE', 'label': '60 cm Triple Spot (WA Indoor)'},
    {'value': 'WA_80CM_SPOT', 'label': '80 cm Spot (WA Indoor Compound)'},
  ];

  Future<String?> _requireToken({
    bool showMissingTokenSnackbar = true,
    bool setPageErrorOnMissing = false,
  }) async {
    final token = await TokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      return token;
    }
    if (!mounted) return null;
    if (setPageErrorOnMissing) {
      setState(() {
        _error = 'Missing token';
        _loading = false;
      });
    }
    if (showMissingTokenSnackbar) {
      AppSnackbar.show(context, 'Bitte erst einloggen');
    }
    return null;
  }

  Future<List<TournamentListItem>?> _fetchTournaments({
    required String token,
    required bool forceRefresh,
    String? errorSnackbarMessage,
  }) async {
    try {
      final raw = await ApiService().getTournaments(
        token,
        forceRefresh: forceRefresh,
      );
      return toTournamentItems(raw);
    } catch (e) {
      if (await _redirectToLoginIfAuthExpired(e)) return null;
      if (!mounted) return null;
      if (errorSnackbarMessage != null) {
        AppSnackbar.show(context, errorSnackbarMessage);
      }
      return null;
    }
  }

  Future<void> _loadTournaments() async {
    final token = await _requireToken(
      showMissingTokenSnackbar: false,
      setPageErrorOnMissing: true,
    );
    if (token == null) return;

    final refreshed = await _fetchTournaments(token: token, forceRefresh: true);
    if (refreshed == null) {
      if (!mounted) return;
      setState(() {
        _error = 'Tournamente konnte nicht geladen';
        _loading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _items = refreshed;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _refreshTournaments() async {
    final token = await _requireToken();
    if (token == null) return;

    final refreshed = await _fetchTournaments(
      token: token,
      forceRefresh: true,
      errorSnackbarMessage: 'Aktualisieren fehlgeschlagen',
    );
    if (refreshed == null || !mounted) return;
    setState(() {
      _items = refreshed;
      _error = null;
    });
  }

  Future<void> _retryLoadTournaments() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _loadTournaments();
  }

  void _showTargetFacePicker() {
    final items = _targetFaces
        .map(
          (item) => SelectionItem<String>(
            value: item['value'] ?? '',
            label: item['label'] ?? '',
          ),
        )
        .toList(growable: false);
    showSelectionBottomSheet<String>(
      context: context,
      items: items,
      onSelected: (value) {
        final label = _targetFaces
            .firstWhere(
              (item) => item['value'] == value,
              orElse: () => const {'label': '', 'value': ''},
            )['label']!;
        setState(() {
          _targetFace = value;
          _targetFaceController.text = label;
        });
      },
    );
  }

  Future<void> _createTournament(VoidCallback closeSheet) async {
    if (_nameController.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Bitte Name eingeben');
      return;
    }
    if (_targetFace == null || _targetFace!.isEmpty) {
      AppSnackbar.show(context, 'Bitte TargetFace auswählen');
      return;
    }

    final token = await _requireToken();
    if (token == null) return;

    try {
      await ApiService().createTournament(
        token,
        id: generateTournamentId(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        passesTotal: _passesTotal,
        arrowsPerPass: _arrowsPerPass,
        targetFace: _targetFace!,
        status: 'DRAFT',
        hostShoots: _hostShoots,
      );
    } catch (e) {
      if (await _redirectToLoginIfAuthExpired(e)) return;
      if (!mounted) return;
      AppSnackbar.show(context, 'Tournament konnte nicht erstellt werden');
      return;
    }

    closeSheet();
    _resetCreateForm();
    await _loadTournaments();
  }

  void _resetCreateForm() {
    _nameController.text = _defaultTournamentName;
    _descriptionController.text = _defaultTournamentDescription;
    _locationController.clear();
    _targetFaceController.clear();
    if (mounted) {
      setState(() {
        _targetFace = null;
        _hostShoots = true;
        _passesTotal = 6;
        _arrowsPerPass = 3;
      });
    }
  }

  Future<bool> _deleteTournament(TournamentListItem item) async {
    final token = await _requireToken();
    if (token == null) return false;

    try {
      await ApiService().deleteTournament(token, tournamentId: item.id);
      if (!mounted) return false;
      setState(() {
        _items = _items.where((it) => it.id != item.id).toList(growable: false);
        _swipeOffsets.remove(item.id);
      });
      AppSnackbar.show(context, 'Tournament gelöscht');
      return true;
    } catch (e) {
      if (await _redirectToLoginIfAuthExpired(e)) return false;
      if (!mounted) return false;
      AppSnackbar.show(context, 'Löschen fehlgeschlagen');
      return false;
    }
  }

  Future<bool> _stopTournament(TournamentListItem item) async {
    final token = await _requireToken();
    if (token == null) return false;

    try {
      await ApiService().updateTournamentStatus(
        token,
        tournamentId: item.id,
        status: 'FINISHED',
      );
      if (!mounted) return false;
      setState(() {
        _items = _items
            .map(
              (it) => it.id == item.id
                  ? TournamentListItem(
                      id: it.id,
                      hostUserId: it.hostUserId,
                      name: it.name,
                      description: it.description,
                      location: it.location,
                      status: 'FINISHED',
                      publicKey: it.publicKey,
                      participants: it.participants,
                      passesTotal: it.passesTotal,
                      arrowsPerPass: it.arrowsPerPass,
                      targetFace: it.targetFace,
                      startTime: it.startTime,
                      endTime: it.endTime,
                      createdAt: it.createdAt,
                    )
                  : it,
            )
            .toList(growable: false);
        _swipeOffsets.remove(item.id);
      });
      AppSnackbar.show(context, 'Tournament in History verschoben');
      return true;
    } catch (e) {
      if (await _redirectToLoginIfAuthExpired(e)) return false;
      if (!mounted) return false;
      AppSnackbar.show(context, 'Stoppen fehlgeschlagen');
      return false;
    }
  }

  Future<bool> _redirectToLoginIfAuthExpired(Object error) async {
    if (!error.toString().contains('AUTH_EXPIRED') || _redirectingToLogin) {
      return false;
    }
    _redirectingToLogin = true;
    await TokenStorage.clearToken();
    if (!mounted) return true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  @override
  void reassemble() {
    super.reassemble();
    _scheduleReloadAfterHotReload();
  }

  void _scheduleReloadAfterHotReload() {
    if (!mounted || _reloadScheduled) return;
    _reloadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _reloadScheduled = false;
      if (!mounted) return;
      await _refreshTournaments();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _targetFaceController.dispose();
    super.dispose();
  }

  void _onCardDragUpdate(TournamentListItem item, DragUpdateDetails details) {
    final current = _swipeOffsets[item.id] ?? 0;
    final next = (current + details.delta.dx).clamp(-_deleteRevealWidth, 0.0);
    setState(() {
      _swipeOffsets[item.id] = next;
    });
  }

  void _onCardDragEnd(TournamentListItem item) {
    final current = _swipeOffsets[item.id] ?? 0;
    final shouldOpen = current.abs() > (_deleteRevealWidth / 2);
    setState(() {
      _swipeOffsets[item.id] = shouldOpen ? -_deleteRevealWidth : 0;
    });
  }

  void _openTournamentPage(TournamentListItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentDetailPage(
          tournamentName: item.name,
        ),
      ),
    );
  }

  Future<void> _openParticipantsPage(TournamentListItem item) async {
    _suppressNextCardTapItemId = item.id;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentParticipantsPage(
          tournamentId: item.id,
          tournamentName: item.name,
          currentParticipants: item.participants ?? 0,
          initialTargetFace: item.targetFace,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshTournaments();
  }

  Future<void> _updateTournament(
    TournamentListItem item,
    VoidCallback closeSheet,
  ) async {
    if (_nameController.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Bitte Name eingeben');
      return;
    }
    if (_targetFace == null || _targetFace!.isEmpty) {
      AppSnackbar.show(context, 'Bitte TargetFace auswählen');
      return;
    }

    final token = await _requireToken();
    if (token == null) return;

    try {
      await ApiService().updateTournamentDetails(
        token,
        tournamentId: item.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        passesTotal: _passesTotal,
        arrowsPerPass: _arrowsPerPass,
        targetFace: _targetFace!,
        status: item.status,
        hostShoots: _hostShoots,
      );
      if (!mounted) return;
      closeSheet();
      AppSnackbar.show(context, 'Tournament aktualisiert');
      await _refreshTournaments();
    } catch (e) {
      if (await _redirectToLoginIfAuthExpired(e)) return;
      if (!mounted) return;
      AppSnackbar.show(context, 'Aktualisieren fehlgeschlagen');
    }
  }

  Future<void> _showKeyQrDialog(TournamentListItem item) async {
    final keyValue = item.publicKey?.toString();
    if (keyValue == null || keyValue.isEmpty) {
      AppSnackbar.show(context, 'Kein Key vorhanden');
      return;
    }

    _suppressNextCardTapItemId = item.id;
    if (!mounted) return;
    final rootContext = context;
    await showGeneralDialog<void>(
      context: rootContext,
      barrierDismissible: true,
      barrierLabel: 'QR-Code',
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final theme = Theme.of(dialogContext);
        final schema = theme.colorScheme;
        return Center(
          child: Dialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 280,
                maxWidth: 340,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'QR-Code',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: schema.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: keyValue,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      keyValue,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: schema.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Schließen',
                          style: TextStyle(color: schema.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  void openCreateSheet() {
    _openCreateSheet(context);
  }

  void _openCreateSheet(BuildContext context) {
    _resetCreateForm();
    late PersistentBottomSheetController controller;
    controller = Scaffold.of(context).showBottomSheet(
      (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final height = media.size.height -
            kBottomNavigationBarHeight -
            media.padding.bottom -
            72;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return TournamentCreateSheet(
              height: height,
              onClose: () => controller.close(),
              nameController: _nameController,
              descriptionController: _descriptionController,
              locationController: _locationController,
              targetFaceController: _targetFaceController,
              hostShoots: _hostShoots,
              onHostShootsChanged: (value) {
                setSheetState(() {
                  _hostShoots = value;
                });
              },
              passesTotal: _passesTotal,
              arrowsPerPass: _arrowsPerPass,
              onPassesMinus: () {
                setSheetState(() {
                  if (_passesTotal > 6) _passesTotal -= 1;
                });
              },
              onPassesPlus: () {
                setSheetState(() {
                  if (_passesTotal < 10) _passesTotal += 1;
                });
              },
              onArrowsMinus: () {
                setSheetState(() {
                  if (_arrowsPerPass > 3) _arrowsPerPass -= 1;
                });
              },
              onArrowsPlus: () {
                setSheetState(() {
                  if (_arrowsPerPass < 6) _arrowsPerPass += 1;
                });
              },
              onPickTargetFace: _showTargetFacePicker,
              onCreate: () => _createTournament(controller.close),
            );
          },
        );
      },
    );
  }

  void _openEditSheet(TournamentListItem item) {
    _nameController.text = item.name;
    _descriptionController.text = item.description;
    _locationController.text = item.location;
    _targetFace = item.targetFace;
    _targetFaceController.text = targetFaceLabelForValue(
      item.targetFace,
      _targetFaces,
    );
    _passesTotal = item.passesTotal ?? 6;
    _arrowsPerPass = item.arrowsPerPass ?? 3;
    _hostShoots = true;

    late PersistentBottomSheetController controller;
    controller = Scaffold.of(context).showBottomSheet(
      (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final height = media.size.height -
            kBottomNavigationBarHeight -
            media.padding.bottom -
            72;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return TournamentCreateSheet(
              height: height,
              onClose: () => controller.close(),
              title: 'Tournament bearbeiten',
              submitLabel: 'Speichern',
              nameController: _nameController,
              descriptionController: _descriptionController,
              locationController: _locationController,
              targetFaceController: _targetFaceController,
              hostShoots: _hostShoots,
              onHostShootsChanged: (value) {
                setSheetState(() {
                  _hostShoots = value;
                });
              },
              passesTotal: _passesTotal,
              arrowsPerPass: _arrowsPerPass,
              onPassesMinus: () {
                setSheetState(() {
                  if (_passesTotal > 6) _passesTotal -= 1;
                });
              },
              onPassesPlus: () {
                setSheetState(() {
                  if (_passesTotal < 10) _passesTotal += 1;
                });
              },
              onArrowsMinus: () {
                setSheetState(() {
                  if (_arrowsPerPass > 3) _arrowsPerPass -= 1;
                });
              },
              onArrowsPlus: () {
                setSheetState(() {
                  if (_arrowsPerPass < 6) _arrowsPerPass += 1;
                });
              },
              onPickTargetFace: _showTargetFacePicker,
              onCreate: () => _updateTournament(item, controller.close),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TournamentPageBody(
      items: _items,
      loading: _loading,
      error: _error,
      swipeOffsets: _swipeOffsets,
      suppressNextCardTapItemId: _suppressNextCardTapItemId,
      navIconGreenLight: _navIconGreenLight,
      navIconGreenDark: _navIconGreenDark,
      deleteRevealWidth: _deleteRevealWidth,
      onRefresh: _refreshTournaments,
      onRetryLoad: _retryLoadTournaments,
      onCardDragUpdate: _onCardDragUpdate,
      onCardDragEnd: _onCardDragEnd,
      onCardTap: (item, offset) {
        if (_suppressNextCardTapItemId == item.id) {
          _suppressNextCardTapItemId = null;
          return;
        }
        if (offset.abs() > 0) {
          setState(() {
            _swipeOffsets[item.id] = 0;
          });
          return;
        }
        _openTournamentPage(item);
      },
      onDeleteOrStopPressed: (item) async {
        if (item.status.toUpperCase() == 'RUNNING') {
          await _stopTournament(item);
        } else {
          await _deleteTournament(item);
        }
      },
      onMenuAction: (item, action) async {
        if (action == 'key_qr') {
          await _showKeyQrDialog(item);
          return;
        }
        if (action == 'participants') {
          await _openParticipantsPage(item);
          return;
        }
        if (action == 'edit') {
          _openEditSheet(item);
          return;
        }
        if (action == 'stop') {
          await _stopTournament(item);
        }
      },
    );
  }
}
