import 'package:bowsocial_app/components/app_buttons.dart';
import 'package:bowsocial_app/components/app_links.dart';
import 'package:bowsocial_app/components/app_text_field.dart';
import 'package:bowsocial_app/components/auth_header.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _submitted = false;

  bool _emailHasError = false;
  bool _usernameHasError = false;
  bool _passwordHasError = false;

  bool _shouldValidate(String value) {
    return _submitted || value.isNotEmpty;
  }

  bool _isEmailValid(String email) {
    final pattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return email.isNotEmpty && pattern.hasMatch(email);
  }

  bool _isUsernameValid(String username) {
    final usernamePattern = RegExp(
      r'^(?=.{3,30}$)(?![_.-])(?!.*[_.-]{2})(?!.*\s{2})[a-zA-Z0-9._-]+(\s[a-zA-Z0-9._-]+)?(?<![_.-])$',
    );
    final notOnlyNumbers = RegExp(r'.*[a-zA-Z].*');
    return username.isNotEmpty &&
        usernamePattern.hasMatch(username) &&
        notOnlyNumbers.hasMatch(username);
  }

  bool _isPasswordValid(String password) {
    final passwordPattern = RegExp(
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-={}\[\]:,.?]).{8,}$',
    );
    final dangerousPattern = RegExp(".*[<>\"'%;)(&+].*");
    if (dangerousPattern.hasMatch(password)) {
      return false;
    }
    return passwordPattern.hasMatch(password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(title: 'Registrieren'),
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
                      const SizedBox(height: 32),
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
                        errorMessage: 'Bitte gueltige Email eingeben',
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _usernameController,
                        label: 'Benutzername',
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        onChanged: (value) {
                          final username = value.trim();
                          final shouldValidate = _shouldValidate(username);
                          setState(() {
                            _usernameHasError =
                                shouldValidate && !_isUsernameValid(username);
                          });
                        },
                        hasError: _usernameHasError,
                        showErrorIcon: true,
                        errorMessage:
                            'Regeln: 3-30 Zeichen, Buchstaben/Zahlen/._-, optional ein Leerzeichen, nicht nur Zahlen, kein Start/Ende mit ._- und keine doppelten ._-',
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Passwort',
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        obscureText: _obscure,
                        onChanged: (value) {
                          final password = value;
                          final shouldValidate = _shouldValidate(password);
                          setState(() {
                            _passwordHasError =
                                shouldValidate && !_isPasswordValid(password);
                          });
                        },
                        hasError: _passwordHasError,
                        showErrorIcon: true,
                        showPasswordToggle: true,
                        errorMessage:
                            'Passwortregeln: min. 8 Zeichen, 1 Grossbuchstabe, 1 Zahl, 1 Sonderzeichen, keine <>\"\'%;)(&+',
                        onToggleObscure: () {
                          setState(() => _obscure = !_obscure);
                        },
                      ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        label: 'Registrieren',
                        onPressed: () {
                          setState(() {
                            _submitted = true;
                            final email = _emailController.text.trim();
                            final username = _usernameController.text.trim();
                            final password = _passwordController.text;
                            _emailHasError = !_isEmailValid(email);
                            _usernameHasError = !_isUsernameValid(username);
                            _passwordHasError = !_isPasswordValid(password);
                          });

                          if (!(_emailHasError ||
                              _usernameHasError ||
                              _passwordHasError)) {
                            // TODO: Registrierung ausfuehren
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ich habe ein Konto?',
                            style: TextStyle(color: schema.secondary),
                          ),
                          const SizedBox(width: 6),
                          AppLinkText(
                            text: 'Log in',
                            onPressed: () {
                              Navigator.of(context).pop();
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
