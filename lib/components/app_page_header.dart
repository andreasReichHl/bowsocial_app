import 'package:flutter/material.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.centerTitle = false,
    this.titleColor,
    this.showBottomBorder = true,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;
  final Color? titleColor;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final leadingWidgets = leading == null
        ? null
        : <Widget>[
            leading!,
            const SizedBox(width: 8),
          ];
    final trailingWidgets = trailing == null ? null : <Widget>[trailing!];
    final chromeBg = theme.brightness == Brightness.light
        ? Color.alphaBlend(
            Colors.white.withAlpha(120),
            theme.scaffoldBackgroundColor,
          )
        : Color.alphaBlend(
            Colors.white.withAlpha(18),
            theme.scaffoldBackgroundColor,
          );

    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 10, 16, 10),
      decoration: BoxDecoration(
        color: chromeBg,
        border: showBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: schema.secondary.withAlpha(60),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: centerTitle
          ? Stack(
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
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor ?? schema.secondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 18,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                ...?leadingWidgets,
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: titleColor ?? schema.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...?trailingWidgets,
              ],
            ),
    );
  }
}
