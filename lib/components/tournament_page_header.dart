import 'package:flutter/material.dart';

class TournamentPageHeader extends StatelessWidget {
  const TournamentPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.uppercase = true,
    this.bottom,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool uppercase;
  final Widget? bottom;

  static const Color _navIconGreenLight = Color(0xFF6D863E);
  static const Color _navIconGreenDark = Color(0xFF8FB339);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final navAccent = theme.brightness == Brightness.light
        ? _navIconGreenLight
        : _navIconGreenDark;
    final chromeBg = theme.brightness == Brightness.light
        ? Color.alphaBlend(
            Colors.white.withAlpha(120),
            theme.scaffoldBackgroundColor,
          )
        : Color.alphaBlend(
            Colors.white.withAlpha(18),
            theme.scaffoldBackgroundColor,
          );
    final resolvedTitle = uppercase ? title.toUpperCase() : title;
    final leadingWidgets = leading == null
        ? null
        : <Widget>[
            leading!,
            const SizedBox(width: 8),
          ];
    final trailingWidgets = trailing == null ? null : <Widget>[trailing!];

    return Container(
      decoration: BoxDecoration(
        color: chromeBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.brightness == Brightness.light ? 28 : 44),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 10,
              16,
              bottom == null ? 10 : 6,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    ...?leadingWidgets,
                    const Spacer(),
                    ...?trailingWidgets,
                  ],
                ),
                Text(
                  resolvedTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: navAccent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          if (bottom != null) ...[
            bottom!,
            Container(
              height: 1,
              color: schema.secondary.withAlpha(36),
            ),
          ],
        ],
      ),
    );
  }
}
