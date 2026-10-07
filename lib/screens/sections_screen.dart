import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/section_model.dart';
import '../providers/section_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_state_views.dart';
import '../widgets/premium_widgets.dart';
import 'game_screen.dart';

class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});

  static const routeName = '/sections';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Бөлүмдөр'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Оюн эрежеси',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showRulesDialog(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<SectionModel>>(
        stream: context.read<SectionProvider>().watchSections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            return ErrorView(message: snapshot.error.toString());
          }

          final sections = snapshot.data ?? const <SectionModel>[];
          if (sections.isEmpty) {
            return const EmptyView(message: 'Бөлүмдөр азырынча жок.');
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: sections.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final section = sections[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 320 + (index * 60)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 16),
                      child: child,
                    ),
                  );
                },
                child: _SectionCard(section: section),
              );
            },
          );
        },
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Система кантип иштейт?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _RuleTile(
                      icon: Icons.translate_rounded,
                      color: Color(0xFF3B82F6),
                      title: 'Туура котормосун тандаңыз',
                      description:
                          'Экранда түркчө сөз көрсөтүлөт. Төмөндөн анын туура кыргызча маанисин тандаңыз.',
                    ),
                    const SizedBox(height: 14),
                    const _RuleTile(
                      icon: Icons.repeat_rounded,
                      color: Color(0xFF10B981),
                      title: '5 жолу катары менен туура жооп',
                      description:
                          'Бир эле сөзгө 5 жолу катары менен туура жооп берсеңиз, ал сөз жатталды деп эсептелет.',
                    ),
                    const SizedBox(height: 14),
                    const _RuleTile(
                      icon: Icons.close_rounded,
                      color: Color(0xFFEF4444),
                      title: 'Ката жооп',
                      description:
                          'Эгер жаңылыш жооп берсеңиз, ошол сөздүн сериясы (streak) кайра 0 болуп башталат.',
                    ),
                    const SizedBox(height: 14),
                    const _RuleTile(
                      icon: Icons.bolt_rounded,
                      color: Color(0xFFF59E0B),
                      title: 'XP системасы',
                      description:
                          'Туура жооп үчүн +4 XP, туура эмес жооп үчүн −1 XP берилет.',
                    ),
                    const SizedBox(height: 14),
                    const _RuleTile(
                      icon: Icons.auto_awesome_rounded,
                      color: Color(0xFF8B5CF6),
                      title: 'Жатталган сөздөр',
                      description:
                          'Жатталган сөздөр кайра суроо болуп чыкпайт. Алардын ордуна жаңы сөздөр келет.',
                    ),
                    const SizedBox(height: 14),
                    const _RuleTile(
                      icon: Icons.flag_rounded,
                      color: Color(0xFF06B6D4),
                      title: 'Раунд',
                      description:
                          'Активдүү сөздөрдүн баарына туура жооп бергенден кийин жаңы раундду баштай аласыз.',
                    ),
                    const SizedBox(height: 14),
                    const _RuleTile(
                      icon: Icons.emoji_events_rounded,
                      color: Color(0xFFEAB308),
                      title: 'Бөлүм аяктайт',
                      description:
                          'Бөлүмдөгү бардык сөздөр жатталганда бөлүм толугу менен аяктайт.',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('💡', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Кеңеш: Сөздөрдү күн сайын кайталап турсаңыз, алар узак убакытка эсте сакталат.',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          'Түшүндүм',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final SectionModel section;

  @override
  Widget build(BuildContext context) {
    final progress = section.progressPercent.clamp(0, 100) / 100;

    return PremiumCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                GameScreen(sectionId: section.id, sectionTitle: section.title),
          ),
        );
      },
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.16),
                      AppColors.primary.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  section.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${section.progressPercent}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                minHeight: 9,
                value: value,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                icon: Icons.style_rounded,
                label: '${section.totalWords} сөз',
                color: const Color(0xFF6366F1),
              ),
              _StatChip(
                icon: Icons.check_circle_rounded,
                label: '${section.masteredWords} жатталган сөз',
                color: const Color(0xFF10B981),
              ),
              _StatChip(
                icon: Icons.trending_up_rounded,
                label: '${section.progressPercent}%',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
