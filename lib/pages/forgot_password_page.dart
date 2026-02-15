import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passwort vergessen')),
      body: const SafeArea(
        child: Center(
          child: Text('Hier kommt die Passwort-zuruecksetzen-Seite hin.'),
        ),
      ),
    );
  }
}
