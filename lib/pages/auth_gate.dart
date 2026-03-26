import 'package:bowsocial_app/api/api_service.dart';
import 'package:bowsocial_app/pages/dashboard_page.dart';
import 'package:bowsocial_app/pages/login_page.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _authFuture;
  String? _authFailureMessage;
  bool _authFailureShown = false;

  @override
  void initState() {
    super.initState();
    _authFuture = _checkAuth();
  }

  Future<bool> _checkAuth() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAuthed = snapshot.data ?? false;
        if (!isAuthed &&
            !_authFailureShown &&
            _authFailureMessage != null &&
            mounted) {
          _authFailureShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final message = _authFailureMessage;
            if (message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          });
        }
        return isAuthed ? const DashboardPage() : const LoginPage();
      },
    );
  }
}
