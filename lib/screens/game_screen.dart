import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word_model.dart';
import '../providers/game_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_state_views.dart';
import '../widgets/premium_widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.sectionId,
    required this.sectionTitle,
    super.key,
  });

  final String sectionId;
  final String sectionTitle;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _completionDialogVisible = false;
  bool _roundDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startSection(
        sectionId: widget.sectionId,
        sectionTitle: widget.sectionTitle,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (gameProvider.status == GameStatus.completed) {
          _showCompletionDialog(gameProvider);
        } else if (gameProvider.status == GameStatus.roundCompleted) {
          _showRoundDialog(gameProvider);
        } else {
          _completionDialogVisible = false;
          _roundDialogVisible = false;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.sectionTitle),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${gameProvider.sessionXp} упай',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: _GameBody(gameProvider: gameProvider),
        );
      },
    );
  }

  void _showCompletionDialog(GameProvider gameProvider) {
    if (_completionDialogVisible) {
      return;
    }

    _completionDialogVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.emoji_events, color: AppColors.correct),
            title: const Text('Бөлүм аяктады'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Топтолгон упай: ${gameProvider.sessionXp}'),
                Text('Туура жооптор: ${gameProvider.sessionCorrectAnswers}'),
                Text('Ката жооптор: ${gameProvider.sessionWrongAnswers}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await context.read<GameProvider>().restartSection();
                  _completionDialogVisible = false;
                },
                child: const Text('Бөлүмдү кайра баштоо'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Бөлүмдөргө кайтуу'),
              ),
            ],
          );
        },
      );
    });
  }

  void _showRoundDialog(GameProvider gameProvider) {
    if (_roundDialogVisible) {
      return;
    }

    _roundDialogVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final totalAnswers =
          gameProvider.roundCorrectAnswers + gameProvider.roundWrongAnswers;
      final accuracy = totalAnswers == 0
          ? 0
          : ((gameProvider.roundCorrectAnswers / totalAnswers) * 100).round();

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.flag, color: AppColors.primary),
            title: const Text('Оюн аяктады'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Туура жооптор: ${gameProvider.roundCorrectAnswers}'),
                Text('Ката жооптор: ${gameProvider.roundWrongAnswers}'),
                Text('Тактык: $accuracy%'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<GameProvider>().playAgain();
                  _roundDialogVisible = false;
                },
                child: const Text('Кайра ойноо'),
              ),
              FilledButton(
                onPressed: () {
                  _roundDialogVisible = false;

                  context.read<GameProvider>().resetGameState();

                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Чыгуу'),
              ),
            ],
          );
        },
      );
    });
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({required this.gameProvider});

  final GameProvider gameProvider;

  @override
  Widget build(BuildContext context) {
    switch (gameProvider.status) {
      case GameStatus.initial:
      case GameStatus.loading:
        return const LoadingView();
      case GameStatus.empty:
        return const EmptyView(message: 'Бул бөлүмдө сөздөр жок.');
      case GameStatus.error:
        return ErrorView(message: gameProvider.errorMessage ?? 'Ката кетти.');
      case GameStatus.roundCompleted:
        return _RoundCompletedGame(gameProvider: gameProvider);
      case GameStatus.completed:
        return const EmptyView(message: 'Бөлүм аяктады');
      case GameStatus.ready:
        return _ReadyGame(gameProvider: gameProvider);
    }
  }
}

class _RoundCompletedGame extends StatelessWidget {
  const _RoundCompletedGame({required this.gameProvider});

  final GameProvider gameProvider;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: const ScreenHeader(
                    icon: Icons.flag,
                    title: 'Оюн аяктады',
                    subtitle: 'Натыйжаны көрүү үчүн тандоо жасаңыз.',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _AnswerGrid(gameProvider: gameProvider),
          ],
        ),
      ),
    );
  }
}

class _ReadyGame extends StatelessWidget {
  const _ReadyGame({required this.gameProvider});

  final GameProvider gameProvider;

  @override
  Widget build(BuildContext context) {
    final currentWord = gameProvider.currentWord;
    if (currentWord == null) {
      return const EmptyView(message: 'Бул бөлүмдө сөздөр жок.');
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            _RoundStats(gameProvider: gameProvider),
            const SizedBox(height: 12),
            Expanded(
              // LayoutBuilder + SingleChildScrollView instead of a plain
              // Center: the word card keeps the exact same font size on
              // every device, but if a word is too tall/wide to fit the
              // available space on a small phone, the user can scroll to
              // see it instead of it being clipped and disappearing.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        minWidth: constraints.maxWidth,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: _TurkishWordCard(
                            key: ValueKey(currentWord.id),
                            word: currentWord,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _AnswerGrid(gameProvider: gameProvider),
          ],
        ),
      ),
    );
  }
}

class _TurkishWordCard extends StatelessWidget {
  const _TurkishWordCard({required this.word, super.key});

  final WordModel word;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PremiumCard(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: Text(
          word.turkish,
          textAlign: TextAlign.center,
          // No maxLines / no scaling: every word is shown at the exact
          // same font size. Long words simply wrap onto a new line
          // instead of shrinking or getting cut off.
          softWrap: true,
          style: textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AnswerGrid extends StatelessWidget {
  const _AnswerGrid({required this.gameProvider});

  final GameProvider gameProvider;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gameProvider.activePool.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 86,
        mainAxisSpacing: 10,
        crossAxisSpacing: 7,
      ),
      itemBuilder: (context, index) {
        final answer = gameProvider.activePool[index];
        return _AnswerButton(
          key: ValueKey(answer.id),
          gameProvider: gameProvider,
          answer: answer,
        );
      },
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.gameProvider,
    required this.answer,
    super.key,
  });

  final GameProvider gameProvider;
  final WordModel answer;

  @override
  Widget build(BuildContext context) {
    final selected = gameProvider.selectedWordId == answer.id;
    final isCorrectSelection = gameProvider.selectedAnswerIsCorrect ?? false;
    final isDisabled =
        gameProvider.isDisabledDistractor(answer) ||
        gameProvider.isSolvedAnswer(answer);
    final Color backgroundColor;
    final Color foregroundColor;

    if (selected && isCorrectSelection) {
      backgroundColor = AppColors.correct;
      foregroundColor = AppColors.textPrimary;
    } else if (gameProvider.isSolvedAnswer(answer)) {
      backgroundColor = AppColors.success;
      foregroundColor = Colors.white;
    } else if (selected) {
      backgroundColor = AppColors.wrong;
      foregroundColor = Colors.white;
    } else {
      backgroundColor = AppColors.card;
      foregroundColor = AppColors.textPrimary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.48),
          elevation: selected ? 2 : 0,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
        ),
        onPressed: isDisabled
            ? null
            : () => context.read<GameProvider>().selectAnswer(answer),
        child: Text(
          answer.kyrgyz,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _RoundStats extends StatelessWidget {
  const _RoundStats({required this.gameProvider});

  final GameProvider gameProvider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatPill(
            icon: Icons.check_circle,
            label: 'Туура',
            value: '${gameProvider.roundCorrectAnswers}',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatPill(
            icon: Icons.cancel,
            label: 'Ката',
            value: '${gameProvider.roundWrongAnswers}',
            color: AppColors.wrong,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatPill(
            icon: Icons.bolt,
            label: 'Упай',
            value: '${gameProvider.sessionXp}',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
