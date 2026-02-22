import 'package:bowsocial_app/api/api_service.dart';
import 'package:bowsocial_app/components/app_buttons.dart';
import 'package:bowsocial_app/pages/login_page.dart';
import 'package:bowsocial_app/theme/app_theme_controller.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await TokenStorage.clearToken();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = AppThemeController.of(context);
    final isDark = themeController.value == ThemeMode.dark;
    final schema = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dark Mode (Test)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: schema.secondary,
                  ),
            ),
            Switch(
              value: isDark,
              onChanged: (value) {
                themeController.value =
                    value ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Logout',
          onPressed: () => _logout(context),
        ),
      ],
    );
  }
}
