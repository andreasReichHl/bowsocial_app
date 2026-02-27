import 'package:bowsocial_app/components/app_buttons.dart';
import 'package:bowsocial_app/components/app_text_field.dart';
import 'package:flutter/material.dart';

class TournamentCreateSheet extends StatelessWidget {
  final double height;
  final VoidCallback onClose;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final TextEditingController targetFaceController;
  final bool hostShoots;
  final ValueChanged<bool> onHostShootsChanged;
  final VoidCallback onPickTargetFace;
  final VoidCallback onCreate;
  final String title;
  final String submitLabel;
  final int passesTotal;
  final int arrowsPerPass;
  final VoidCallback onPassesMinus;
  final VoidCallback onPassesPlus;
  final VoidCallback onArrowsMinus;
  final VoidCallback onArrowsPlus;

  const TournamentCreateSheet({
    super.key,
    required this.height,
    required this.onClose,
    required this.nameController,
    required this.descriptionController,
    required this.locationController,
    required this.targetFaceController,
    required this.hostShoots,
    required this.onHostShootsChanged,
    required this.onPickTargetFace,
    required this.onCreate,
    this.title = 'Neues Tournament',
    this.submitLabel = 'Anlegen',
    required this.passesTotal,
    required this.arrowsPerPass,
    required this.onPassesMinus,
    required this.onPassesPlus,
    required this.onArrowsMinus,
    required this.onArrowsPlus,
  });

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final schema = Theme.of(context).colorScheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + viewInsets,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    AppTextField(
                      controller: nameController,
                      label: 'Name',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: descriptionController,
                      label: 'Beschreibung',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: locationController,
                      label: 'Ort',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _StepperRow(
                      label: 'Anzahl der Passen',
                      value: passesTotal.toString(),
                      onMinus: onPassesMinus,
                      onPlus: onPassesPlus,
                    ),
                    const SizedBox(height: 10),
                    _StepperRow(
                      label: 'Pfeile pro Passe',
                      value: arrowsPerPass.toString(),
                      onMinus: onArrowsMinus,
                      onPlus: onArrowsPlus,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: targetFaceController,
                      label: 'TargetFace',
                      readOnly: true,
                      onTap: onPickTargetFace,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Ich schiesse mit',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: schema.secondary,
                            ),
                      ),
                      value: hostShoots,
                      onChanged: onHostShootsChanged,
                      activeThumbColor: schema.secondary,
                      activeTrackColor: schema.secondary.withAlpha(60),
                      inactiveThumbColor: schema.secondary,
                      inactiveTrackColor: schema.secondary.withAlpha(60),
                    ),
                    const SizedBox(height: 12),
                    AppPrimaryButton(
                      label: submitLabel,
                      onPressed: onCreate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: schema.secondary,
                ),
          ),
        ),
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove),
          color: schema.secondary,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: schema.secondary,
              ),
        ),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add),
          color: schema.secondary,
        ),
      ],
    );
  }
}
