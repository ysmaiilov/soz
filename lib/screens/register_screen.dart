import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Катталуу')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ScreenHeader(
                          icon: Icons.person_add_alt_1,
                          title: 'Жаңы аккаунт',
                          subtitle: 'Прогрессиңизди сактоо үчүн катталыңыз.',
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Колдонуучу аты',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _validateUsername,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            labelText: 'Электрондук почта',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Сырсөз',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              splashRadius: 20,
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Сырсөздү кайталаңыз',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              splashRadius: 20,
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: _validateConfirmPassword,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (authProvider.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(color: AppColors.wrong),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: authProvider.isLoading ? null : _submit,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Катталуу'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () {
                                  authProvider.clearError();
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Кирүү'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateUsername(String? value) {
    if ((value?.trim() ?? '').length < 3) {
      return 'Колдонуучу аты кеминде 3 белгиден турушу керек.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Электрондук почтаны киргизиңиз.';
    }
    if (!email.contains('@')) {
      return 'Электрондук почта туура эмес.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'Сырсөз кеминде 6 белгиден турушу керек.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Сырсөздү кайра киргизиңиз.';
    }

    if (value != _passwordController.text) {
      return 'Сырсөздөр дал келбейт.';
    }

    return null;
  }
}
