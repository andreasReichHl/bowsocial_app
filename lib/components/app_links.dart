import 'package:flutter/material.dart';

class AppLinkText extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AppLinkText({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          decoration: TextDecoration.underline,
          decorationColor: color,
          decorationThickness: 0.5,
          fontSize: 14,
          color: color,
        ),
      ),
    );
  }
}
