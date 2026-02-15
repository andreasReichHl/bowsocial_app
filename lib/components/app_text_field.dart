import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final String errorMessage;
  final bool showErrorIcon;
  final bool showPasswordToggle;
  final VoidCallback? onToggleObscure;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.onChanged,
    this.hasError = false,
    this.errorMessage = '',
    this.showErrorIcon = false,
    this.showPasswordToggle = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final borderColor = hasError ? Colors.red : schema.secondary;

    Widget? suffixIcon;
    if (showPasswordToggle) {
      suffixIcon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showErrorIcon && hasError) ...[
            Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5),
              message: errorMessage,
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            onPressed: onToggleObscure,
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: schema.secondary,
            ),
          ),
        ],
      );
    } else if (showErrorIcon && hasError) {
      suffixIcon = Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 5),
        message: errorMessage,
        child: const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 20,
        ),
      );
    }

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      onChanged: onChanged,
      style: TextStyle(color: schema.secondary),
      decoration: InputDecoration(
        labelText: label,
        hintText: null,
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        labelStyle: TextStyle(color: schema.secondary),
        floatingLabelStyle: TextStyle(color: schema.secondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
