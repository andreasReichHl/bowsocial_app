import 'package:bowsocial_app/api/api_service.dart';
import 'package:bowsocial_app/components/app_page_header.dart';
import 'package:bowsocial_app/components/app_selection_sheet.dart';
import 'package:bowsocial_app/components/app_snackbar.dart';
import 'package:bowsocial_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class TournamentParticipantsPage extends StatefulWidget {
  const TournamentParticipantsPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.currentParticipants,
    required this.initialTargetFace,
  });

  final String tournamentId;
  final String tournamentName;
  final int currentParticipants;
  final String initialTargetFace;

  @override
  State<TournamentParticipantsPage> createState() =>
      _TournamentParticipantsPageState();
}

class _TournamentParticipantsPageState extends State<TournamentParticipantsPage> {
  static const Color _navIconGreenLight = Color(0xFF6D863E);
  static const Color _navIconGreenDark = Color(0xFF8FB339);
  static const int _maxParticipantsPerDevice = 4;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _targetNoController = TextEditingController();
  final TextEditingController _targetFaceController = TextEditingController();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int _deviceAddedParticipants = 0;
  int _addedInCurrentSession = 0;
  bool _saving = false;
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

  @override
  void initState() {
    super.initState();
    _targetFace = widget.initialTargetFace;
    _targetFaceController.text = _targetFaceLabelForValue(widget.initialTargetFace);
    _loadDeviceAddedParticipants();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _targetNoController.dispose();
    _targetFaceController.dispose();
    super.dispose();
  }

  Future<String?> _requireToken() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return null;
      AppSnackbar.show(context, 'Bitte erst einloggen');
      return null;
    }
    return token;
  }

  Future<bool> _redirectToLoginIfAuthExpired(Object error) async {
    if (!error.toString().contains('AUTH_EXPIRED')) return false;
    await TokenStorage.clearToken();
    if (!mounted) return true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
    return true;
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

  String _targetFaceLabelForValue(String value) {
    final match = _targetFaces.firstWhere(
      (item) => item['value'] == value,
      orElse: () => const {'label': '', 'value': ''},
    );
    return match['label'] ?? '';
  }

  String get _deviceQuotaKey => 'participants_added_${widget.tournamentId}';

  Future<void> _loadDeviceAddedParticipants() async {
    final raw = await _storage.read(key: _deviceQuotaKey);
    final parsed = int.tryParse(raw ?? '') ?? 0;
    if (!mounted) return;
    setState(() {
      _deviceAddedParticipants = parsed.clamp(0, _maxParticipantsPerDevice);
    });
  }

  Future<void> _saveDeviceAddedParticipants(int value) async {
    await _storage.write(key: _deviceQuotaKey, value: value.toString());
  }

  Future<void> _saveParticipant() async {
    if (_deviceAddedParticipants >= _maxParticipantsPerDevice) {
      AppSnackbar.show(context, 'Maximal 4 Teilnehmer pro Gerät möglich');
      return;
    }
    final displayName = _displayNameController.text.trim();
    final targetNo = int.tryParse(_targetNoController.text.trim());
    if (displayName.isEmpty) {
      AppSnackbar.show(context, 'Bitte Anzeigenamen eingeben');
      return;
    }
    if (targetNo == null || targetNo <= 0) {
      AppSnackbar.show(context, 'Bitte eine gültige Scheibennummer eingeben');
      return;
    }
    if (_targetFace == null || _targetFace!.isEmpty) {
      AppSnackbar.show(context, 'Bitte TargetFace auswählen');
      return;
    }

    final token = await _requireToken();
    if (token == null) return;

    setState(() => _saving = true);
    try {
      await ApiService().addTournamentParticipant(
        token,
        tournamentId: widget.tournamentId,
        displayName: displayName,
        targetNo: targetNo,
        targetFace: _targetFace!,
      );
      if (!mounted) return;
      final updatedDeviceCount =
          (_deviceAddedParticipants + 1).clamp(0, _maxParticipantsPerDevice);
      await _saveDeviceAddedParticipants(updatedDeviceCount);
      if (!mounted) return;
      setState(() {
        _deviceAddedParticipants = updatedDeviceCount;
        _addedInCurrentSession += 1;
        _displayNameController.clear();
        _targetNoController.clear();
        _targetFaceController.clear();
        _targetFace = null;
      });
      AppSnackbar.show(context, 'Teilnehmer hinzugefügt');
    } catch (e) {
      if (await _redirectToLoginIfAuthExpired(e)) return;
      if (!mounted) return;
      AppSnackbar.show(context, 'Teilnehmer konnte nicht hinzugefügt werden');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final navAccent = theme.brightness == Brightness.light
        ? _navIconGreenLight
        : _navIconGreenDark;
    final remaining =
        (_maxParticipantsPerDevice - _deviceAddedParticipants).clamp(0, _maxParticipantsPerDevice);
    final currentParticipantsLive =
        widget.currentParticipants + _addedInCurrentSession;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppPageHeader(
            title: 'TEILNEHMER',
            centerTitle: true,
            titleColor: navAccent,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, color: navAccent),
            ),
            trailing: IconButton(
              onPressed: _saving ? null : _saveParticipant,
              icon: Icon(
                Symbols.add_circle,
                color: navAccent,
                size: 30,
                weight: 300,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                Text(
                  widget.tournamentName.isEmpty
                      ? 'Tournament'
                      : widget.tournamentName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: navAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aktuell: $currentParticipantsLive Teilnehmer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: schema.secondary,
                  ),
                ),
                Text(
                  'Noch möglich: $remaining von $_maxParticipantsPerDevice',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: schema.secondary,
                  ),
                ),
                Text(
                  'Auf diesem Gerät hinzugefügt: $_deviceAddedParticipants',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: schema.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Anzeigename',
                    labelStyle: TextStyle(color: schema.secondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: schema.secondary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _targetNoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Scheibennummer',
                    labelStyle: TextStyle(color: schema.secondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: schema.secondary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _showTargetFacePicker,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _targetFaceController,
                      decoration: InputDecoration(
                        labelText: 'TargetFace',
                        labelStyle: TextStyle(color: schema.secondary),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: schema.secondary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: (_saving || _deviceAddedParticipants >= _maxParticipantsPerDevice)
                      ? null
                      : _saveParticipant,
                  style: FilledButton.styleFrom(
                    backgroundColor: schema.surface,
                    foregroundColor: schema.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_saving ? 'Speichert...' : 'Teilnehmer hinzufügen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
