import 'package:bowsocial_app/api/api_service.dart';
import 'package:bowsocial_app/pages/dashboard_page.dart';
import 'package:bowsocial_app/pages/login_page.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkAuth() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    final api = ApiService();
    final isValid = await api.verifyToken(token);
    if (!isValid) {
      await TokenStorage.clearToken();
    }
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAuthed = snapshot.data ?? false;
        return isAuthed ? const DashboardPage() : const LoginPage();
      },
    );
  }
}
