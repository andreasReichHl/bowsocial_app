import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'theme/app_theme.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BowsocialApp());
}



class BowsocialApp extends StatelessWidget {
  const BowsocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bowsocial',
      debugShowCheckedModeBanner: false,

      // 🌗 Dark / Light Mode
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // 🚪 Startseite
      home: const LoginPage(),
    );
  }
}