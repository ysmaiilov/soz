import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/hive_service.dart';
// import '../utils/app_info.dart';
import '../utils/app_theme.dart';
import '../widgets/app_state_views.dart';
import '../widgets/premium_widgets.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isResetting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Жөндөөлөр')),
      body: firebaseUser == null
          ? const ErrorView(message: 'Колдонуучу кирген жок.')
          : StreamBuilder<UserModel?>(
              stream: context.read<UserProvider>().watchCurrentUser(
                firebaseUser.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }

                if (snapshot.hasError) {
                  return ErrorView(message: snapshot.error.toString());
                }

                final user = snapshot.data;
                if (user == null) {
                  return const ErrorView(
                    message: 'Колдонуучу маалыматы табылган жок.',
                  );
                }

                return _SettingsContent(
                  user: user,
                  hiveSizeBytes: context
                      .read<HiveService>()
                      .approximateDatabaseSizeBytes(),
                  isResetting: _isResetting,
                  errorMessage: _errorMessage,
                  onReset: () => _confirmReset(user.id),
                  onLogout: _logout,
                );
              },
            ),
    );
  }

  Future<void> _confirmReset(String uid) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Прогрессти тазалоо'),
          content: const Text(
            'Бул бардык окуу прогрессин жана статистиканы өчүрөт.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Жокко чыгаруу'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Тазалоо'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true || !mounted) {
      return;
    }

    setState(() {
      _isResetting = true;
      _errorMessage = null;
    });

    final hiveService = context.read<HiveService>();
    final userProvider = context.read<UserProvider>();

    try {
      await hiveService.clearProgress();
      await userProvider.resetUserStatistics(uid);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.user,
    required this.hiveSizeBytes,
    required this.isResetting,
    required this.onReset,
    required this.onLogout,
    this.errorMessage,
  });

  final UserModel user;
  final int hiveSizeBytes;
  final bool isResetting;
  final String? errorMessage;
  final VoidCallback onReset;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          ScreenHeader(
            icon: Icons.person,
            title: user.username,
            subtitle: user.email,
          ),
          const SizedBox(height: 16),
          _UserInfoCard(user: user),
          const SizedBox(height: 16),
          _StatisticsCard(user: user),
          const SizedBox(height: 16),

          const _ContactCard(),

          const SizedBox(height: 16),
          // _AppInfoCard(hiveSizeBytes: hiveSizeBytes),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(errorMessage!, style: const TextStyle(color: AppColors.wrong)),
          ],
          const SizedBox(height: 16),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenHeader(
                  icon: Icons.warning_amber,
                  title: 'Кооптуу аракеттер',
                  subtitle:
                      'Бул аракеттер аккаунт жана прогресс маалыматтарына таасир этет.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isResetting ? null : onReset,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.wrong,
                    foregroundColor: Colors.white,
                  ),
                  child: isResetting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 8),
                            Text('Прогрессти тазалоо'),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              icon: const Icon(
                                Icons.logout,
                                color: AppColors.primary,
                              ),
                              title: const Text('Чыгуу'),
                              content: const Text(
                                'Чын эле аккаунттан чыккыңыз келеби?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Жок'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Ооба'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            onLogout();
                          }
                        },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Чыгуу'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const ScreenHeader(icon: Icons.badge_outlined, title: 'Колдонуучу'),
          // const SizedBox(height: 12),
          // _InfoRow(label: 'Аты', value: user.username),
          // _InfoRow(label: 'Электрондук почтасы', value: user.email),
          // _InfoRow(label: 'Упай', value: '${user.xp}'),
          // _InfoRow(label: 'Туура жооптор', value: '${user.correctAnswers}'),
          // _InfoRow(label: 'Ката жооптор', value: '${user.wrongAnswers}'),
        ],
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(
            icon: Icons.analytics_outlined,
            title: 'Статистика',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatPill(
                icon: Icons.check_circle,
                label: 'Туура жооптор',
                value: '${user.correctAnswers}',
                color: AppColors.success,
              ),
              StatPill(
                icon: Icons.cancel,
                label: 'Ката жооптор',
                value: '${user.wrongAnswers}',
                color: AppColors.wrong,
              ),
              StatPill(
                icon: Icons.bolt,
                label: 'Упай',
                value: '${user.xp}',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(
            icon: Icons.support_agent,
            title: 'Жардам жана байланыш',
            subtitle:
                'Сурооңуз, сунушуңуз же ката тууралуу билдирүү жөнөтө аласыз.',
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () => _showContactDialog(context),
            icon: const Icon(Icons.chat),
            label: const Text('Ачуу'),
          ),
        ],
      ),
    );
  }
}

void _showContactDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        icon: const Icon(
          Icons.support_agent,
          color: AppColors.primary,
          size: 40,
        ),
        title: const Text('Жардам жана байланыш'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Колдонмо боюнча сурооңуз болсо, ката байкасаңыз же сунушуңуз болсо, бизге жазыңыз.',
              ),

              const SizedBox(height: 20),

              const Text(
                '📱 Telegram',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openTelegram(dialogContext),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '@r_syimyk',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                '✉️ Email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openEmail(dialogContext),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'googlysmaiilov@gmail.com',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Эмнелер боюнча жаза аласыз?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text('• Ката тууралуу билдирүү'),
              const Text('• Жаңы функция сунуштоо'),
              const Text('• Жаңы сөздөрдү сунуштоо'),
              const Text('• Интерфейс боюнча сунуш'),
              const Text('• Жалпы суроолор'),

              const SizedBox(height: 20),

              const Text(
                '🌱 Колдонмону жакшыраак кылууга жардам бергениңиз үчүн рахмат!',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Түшүнүктүү'),
          ),
        ],
      );
    },
  );
}

Future<void> _openTelegram(BuildContext context) async {
  final Uri url = Uri.parse('https://t.me/r_syimyk');

  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showLaunchError(context, 'Telegram ачылган жок.');
    }
  } catch (_) {
    if (context.mounted) {
      _showLaunchError(context, 'Telegram ачылган жок.');
    }
  }
}

Future<void> _openEmail(BuildContext context) async {
  final Uri url = Uri(
    scheme: 'mailto',
    path: 'googlysmaiilov@gmail.com',
    query: 'subject=Колдонмо боюнча кайрылуу',
  );

  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showLaunchError(context, 'Email колдонмосу ачылган жок.');
    }
  } catch (_) {
    if (context.mounted) {
      _showLaunchError(context, 'Email колдонмосу ачылган жок.');
    }
  }
}

void _showLaunchError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
