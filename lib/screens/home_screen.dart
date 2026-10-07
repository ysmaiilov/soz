import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_state_views.dart';
import '../widgets/premium_widgets.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import 'sections_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firebaseUser = authProvider.currentUser;

    if (firebaseUser == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Башкы бет'),
        actions: [
          IconButton(
            tooltip: 'Жөндөөлөр',
            onPressed: () =>
                Navigator.of(context).pushNamed(SettingsScreen.routeName),
            icon: const Icon(Icons.settings),
          ),
          // TextButton(
          //   onPressed: authProvider.isLoading
          //       ? null
          //       : () async {
          //           await context.read<AuthProvider>().logout();
          //           if (!context.mounted) {
          //             return;
          //           }
          //           Navigator.of(context).pushNamedAndRemoveUntil(
          //             LoginScreen.routeName,
          //             (route) => false,
          //           );
          //         },
          //   child: authProvider.isLoading
          //       ? const SizedBox(
          //           height: 20,
          //           width: 20,
          //           child: CircularProgressIndicator(strokeWidth: 2),
          //         )
          //       : const Text('Чыгуу'),
          // ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: context.read<UserProvider>().watchCurrentUser(firebaseUser.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (userSnapshot.hasError) {
            return ErrorView(message: userSnapshot.error.toString());
          }

          final currentUser = userSnapshot.data;
          if (currentUser == null) {
            return const ErrorView(
              message: 'Колдонуучу маалыматы табылган жок.',
            );
          }

          return _HomeContent(currentUser: currentUser);
        },
      ),
      bottomNavigationBar: StreamBuilder<UserModel?>(
        stream: context.read<UserProvider>().watchCurrentUser(firebaseUser.uid),
        builder: (context, snapshot) {
          final currentUser = snapshot.data;

          return _BottomActions(currentUser: currentUser);
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.currentUser});

  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: context.read<UserProvider>().watchLeaderboard(),
      builder: (context, leaderboardSnapshot) {
        if (leaderboardSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        if (leaderboardSnapshot.hasError) {
          return ErrorView(message: leaderboardSnapshot.error.toString());
        }

        final users = leaderboardSnapshot.data ?? const <UserModel>[];
        final topUsers = users.take(3).toList();
        final currentRank =
            users.indexWhere((user) => user.id == currentUser.id) + 1;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _CurrentUserCard(
                user: currentUser,
                rank: currentRank > 0 ? currentRank : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: PremiumCard(
                color: AppColors.primary.withValues(alpha: 0.08),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dailyMotivation(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.leaderboard, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Үч мыкты каарман',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            Expanded(
              child: users.isEmpty
                  ? const EmptyView(message: 'Лидерборд азырынча бош.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: topUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = topUsers[index];
                        return _LeaderboardTile(
                          rank: index + 1,
                          user: user,
                          isCurrentUser: user.id == currentUser.id,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CurrentUserCard extends StatelessWidget {
  const _CurrentUserCard({required this.user, required this.rank});

  final UserModel user;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            child: Text(
              user.username.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _WhiteBadge(icon: Icons.bolt, label: '${user.xp} упай'),
                    _WhiteBadge(
                      icon: Icons.workspace_premium,
                      label: rank == null ? 'Орун жок' : '#$rank орун',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteBadge extends StatelessWidget {
  const _WhiteBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.user,
    required this.isCurrentUser,
  });

  final int rank;
  final UserModel user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: isCurrentUser ? AppColors.accent.withValues(alpha: 0.35) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCurrentUser
                ? AppColors.primary
                : AppColors.background,
            foregroundColor: isCurrentUser ? Colors.white : AppColors.primary,
            child: Text(_rankLabel(rank)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              user.username,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${user.xp} упай',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rankLabel(int rank) {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.currentUser});

  final UserModel? currentUser;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentUser?.isAdmin ?? false) ...[
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AdminScreen.routeName);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.admin_panel_settings),
                    SizedBox(width: 8),
                    Text('Админ панель'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushNamed(SectionsScreen.routeName);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Баштоо'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dailyMotivation() {
  final messages = [
    '🌱 Бүгүнкү кичинекей аракет — эртеңки чоң ийгилик.',
    '💪 Туруктуулук таланттан да күчтүү.',
    '🚀 Ар бир туура жооп сени максатыңа жакындатат.',
    '🌍 Жаңы тил — жаңы мүмкүнчүлүктөрдүн эшиги.',
    '📖 Билим эң баалуу байлык, аны эч ким тартып ала албайт.',
    '⭐ Бүгүнкү эмгек — эртеңки жеңилдик.',
    '🎯 Аз болсо да, күн сайын аракет кыл.',
    '🌿 Үзгүлтүксүз окуу адамды күн сайын күчтүүрөөк кылат.',
    '🏆 Ийгилик бир күндө эмес, күн сайын жасалган аракеттен жаралат.',
    '📚 Окууга кеткен убакыт — өзүңө жасаган эң жакшы инвестиция.',
    '🤝 Сабыр менен үйрөнүлгөн билим бекем болот.',
    '🌸 Кечээки өзүңдөн жакшыраак болуу — эң чоң жеңиш.',
    '🎓 Билим издеген адам ар дайым өсөт.',
    '🧠 Акылды машыктыруу денени машыктыргандай эле маанилүү.',
    '🌅 Бүгүн башта. Кичинекей кадамдар чоң өзгөрүүгө алып келет.',
  ];

  final day = DateTime.now().day;
  return messages[day % messages.length];
}
