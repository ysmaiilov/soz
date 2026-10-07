import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
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
      appBar: AppBar(title: const Text('Кирүү')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: PremiumCard(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ScreenHeader(
                        icon: Icons.school,
                        title: 'Кош келиңиз',
                        subtitle: 'Окууну улантуу үчүн аккаунтуңузга кириңиз.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Электрондук почта',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Сырсөз',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: _validatePassword,
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
                            : const Text('Кирүү'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                authProvider.clearError();
                                Navigator.of(
                                  context,
                                ).pushNamed(RegisterScreen.routeName);
                              },
                        child: const Text('Катталуу'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
    if ((value ?? '').isEmpty) {
      return 'Сырсөз жазыңыз.';
    }
    return null;
  }
}
