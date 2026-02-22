import 'package:flutter/material.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final schema = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        content: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: schema.onPrimary),
          ),
        ),
      ),
    );
  }
}
