class TargetFaceOption {
  const TargetFaceOption({required this.value, required this.label});

  final String value;
  final String label;
}

const List<TargetFaceOption> targetFaceOptions = [
  TargetFaceOption(value: 'WA_40CM', label: '40 cm (WA Indoor)'),
  TargetFaceOption(value: 'WA_60CM', label: '60 cm (WA)'),
  TargetFaceOption(value: 'WA_80CM', label: '80 cm (WA)'),
  TargetFaceOption(value: 'WA_122CM', label: '122 cm (WA Outdoor)'),
  TargetFaceOption(
    value: 'WA_40CM_TRIPLE',
    label: '40 cm Triple Spot (WA Indoor)',
  ),
  TargetFaceOption(
    value: 'WA_60CM_TRIPLE',
    label: '60 cm Triple Spot (WA Indoor)',
  ),
  TargetFaceOption(
    value: 'WA_80CM_SPOT',
    label: '80 cm Spot (WA Indoor Compound)',
  ),
];

String targetFaceLabelForValue(String value) {
  for (final option in targetFaceOptions) {
    if (option.value == value) return option.label;
  }
  return '';
}
