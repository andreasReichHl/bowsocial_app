import 'package:flutter/material.dart';

class AppThemeController extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const AppThemeController({
    super.key,
    required ValueNotifier<ThemeMode> notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ValueNotifier<ThemeMode> of(BuildContext context) {
    final controller =
        context.dependOnInheritedWidgetOfExactType<AppThemeController>();
    assert(controller != null, 'AppThemeController not found in context');
    return controller!.notifier!;
  }
}
