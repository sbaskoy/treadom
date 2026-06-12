import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_snackbar.dart';
import 'auth_error_messages.dart';

/// Kullanıcı adı + şifre ile yeni hesap oluşturma ekranı.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Kullanıcı adında yalnızca harf, rakam ve alt çizgiye izin verilir.
  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final error = await auth.register(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      showAppSnackBar(
        context,
        localizedAuthError(l10n, error),
        type: AppSnackBarType.error,
      );
      return;
    }

    // Kayıt başarılı: kullanıcı otomatik olarak oturum açtı. Bu ekranı kapatınca
    // kök yönlendirici (AuthGate) oturum akışına göre ana ekranı gösterecek.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.registerTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Kullanıcı adı.
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newUsername],
                    decoration: InputDecoration(
                      labelText: l10n.usernameLabel,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return l10n.validationUsernameRequired;
                      if (text.length < 3) {
                        return l10n.validationUsernameTooShort;
                      }
                      if (!_usernamePattern.hasMatch(text)) {
                        return l10n.validationUsernameInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Şifre.
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.validationPasswordRequired;
                      }
                      if (value.length < 6) {
                        return l10n.validationPasswordTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Şifre tekrar.
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return l10n.validationPasswordMismatch;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.signUpButton),
                  ),
                  const SizedBox(height: 16),

                  // Giriş ekranına geri dön.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.haveAccountPrompt),
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.of(context).pop(),
                        child: Text(l10n.goToLogin),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
