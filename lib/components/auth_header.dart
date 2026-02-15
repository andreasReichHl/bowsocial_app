import 'package:bowsocial_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    final bg = theme.scaffoldBackgroundColor;

    final circle1 = AppColors.decorationMediumGreen;
    final circle2 = AppColors.decorationLightGreen;

    final titleColor = schema.secondary;

    final screenH = MediaQuery.sizeOf(context).height;
    final panelH = screenH * 0.32;

    const panelRadius = BorderRadius.only(
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    );

    return SizedBox(
      height: panelH,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: bg)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: panelH,
            child: ClipRRect(
              borderRadius: panelRadius,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(child: Container(color: schema.surface)),
                  Positioned(
                    top: -220,
                    left: -220,
                    child: _Circle(size: 470, color: circle1),
                  ),
                  Positioned(
                    top: -130,
                    left: -130,
                    child: _Circle(size: 290, color: circle2),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsetsGeometry.only(top: 100),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: titleColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;

  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
