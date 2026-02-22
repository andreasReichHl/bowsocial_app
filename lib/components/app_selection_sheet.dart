import 'package:flutter/material.dart';

class SelectionItem<T> {
  final T value;
  final String label;

  const SelectionItem({
    required this.value,
    required this.label,
  });
}

Future<void> showSelectionBottomSheet<T>({
  required BuildContext context,
  required List<SelectionItem<T>> items,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final schema = Theme.of(sheetContext).colorScheme;
      return ListView(
        shrinkWrap: true,
        children: items.map((item) {
          return ListTile(
            title: Center(
              child: Text(
                item.label,
                style: TextStyle(color: schema.primary),
                textAlign: TextAlign.center,
              ),
            ),
            onTap: () {
              onSelected(item.value);
              Navigator.of(sheetContext).pop();
            },
          );
        }).toList(growable: false),
      );
    },
  );
}
