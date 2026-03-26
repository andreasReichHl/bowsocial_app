import 'dart:async';

import 'package:bowsocial_app/api/api_service.dart';
import 'package:bowsocial_app/components/app_buttons.dart';
import 'package:bowsocial_app/components/app_links.dart';
import 'package:bowsocial_app/components/app_snackbar.dart';
import 'package:bowsocial_app/components/app_text_field.dart';
import 'package:bowsocial_app/components/auth_header.dart';
import 'package:bowsocial_app/pages/dashboard_page.dart';
import 'package:bowsocial_app/pages/forgot_password_page.dart';
import 'package:bowsocial_app/pages/register_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  bool _submitted = false;
  bool _emailHasError = false;
  bool _passwordHasError = false;

  bool _isEmailValid(String email) {
    final pattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return email.isNotEmpty && pattern.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    final pattern = RegExp(".*[<>\"'%;)(&+].*");
    return password.isNotEmpty && !pattern.hasMatch(password);
  }

  bool _shouldValidate(String value) {
    return _submitted || value.isNotEmpty;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _submitted = true;
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      _emailHasError = !_isEmailValid(email);
      _passwordHasError = !_isPasswordValid(password);
    });

    if (_emailHasError || _passwordHasError) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final api = ApiService();
      final token = await api.login(email, password);

      if (token == null || token.isEmpty) {
        throw Exception('Backend hat keinen Token geliefert');
      }

      final userId = TokenStorage.extractUserIdFromJwt(token);

      await TokenStorage.saveToken(token);
      if (userId != null && userId.isNotEmpty) {
        await TokenStorage.saveUserId(userId);
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is TimeoutException
          ? 'Verbindung fehlgeschlagen. Bitte erneut versuchen.'
          : e.toString().contains('AUTH_INVALID')
              ? 'Email oder Passwort falsch!'
              : 'Login fehlgeschlagen';
      AppSnackbar.show(context, message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(title: 'Bowsocial'),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 25),
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (value) {
                          final email = value.trim();
                          final shouldValidate = _shouldValidate(email);
                          setState(() {
                            _emailHasError =
                                shouldValidate && !_isEmailValid(email);
                          });
                        },
                        hasError: _emailHasError,
                        showErrorIcon: true,
                        errorMessage: 'Bitte gültige Email eingeben',
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Passwort',
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onChanged: (value) {
                          final password = value;
                          final shouldValidate = _shouldValidate(password);
                          setState(() {
                            _passwordHasError =
                                shouldValidate && !_isPasswordValid(password);
                          });
                        },
                        obscureText: _obscure,
                        hasError: _passwordHasError,
                        showErrorIcon: true,
                        showPasswordToggle: true,
                        errorMessage: 'Ungültige Zeichen: <>"\'%;)(&+',
                        onToggleObscure: () {
                          setState(() => _obscure = !_obscure);
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AppLinkText(
                          text: 'Passwort vergessen',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        label: 'Login',
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ich habe noch kein Konto?',
                            style: TextStyle(color: schema.secondary),
                          ),
                          const SizedBox(width: 6),
                          AppLinkText(
                            text: 'Registrieren',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
