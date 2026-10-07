import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/section_model.dart';
import '../models/word_model.dart';
import '../providers/section_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_state_views.dart';
import '../widgets/premium_widgets.dart';
import 'bulk_add_words_screen.dart';

class WordManagementArgs {
  const WordManagementArgs({required this.section});

  final SectionModel section;
}

class WordManagementScreen extends StatefulWidget {
  const WordManagementScreen({super.key});

  static const routeName = '/admin/words';

  @override
  State<WordManagementScreen> createState() => _WordManagementScreenState();
}

class _WordManagementScreenState extends State<WordManagementScreen> {
  final _searchController = TextEditingController();
  SectionModel? _section;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _section ??= _sectionFromRoute();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = _section;
    if (section == null) {
      return const Scaffold(body: ErrorView(message: 'Бөлүм берилген жок.'));
    }

    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: StreamBuilder<List<WordModel>>(
        stream: context.read<SectionProvider>().watchWordsForSection(
          section.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            return ErrorView(message: snapshot.error.toString());
          }

          final words = snapshot.data ?? const <WordModel>[];
          final filteredWords = _filterWords(words);

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ScreenHeader(
                        icon: Icons.library_books,
                        title: 'Сөздөр: ${words.length}',
                        subtitle: section.title,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Издөө',
                          hintText: 'Түркчө же кыргызча сөз',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: words.isEmpty
                      ? const EmptyView(message: 'Сөздөр азырынча жок.')
                      : filteredWords.isEmpty
                      ? const EmptyView(message: 'Дал келген сөздөр жок.')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                          itemCount: filteredWords.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final word = filteredWords[index];
                            return _WordCard(section: section, word: word);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(
            BulkAddWordsScreen.routeName,
            arguments: BulkAddWordsArgs(
              section: section,
              returnToWordManagement: true,
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Сөздөрдү кошуу'),
      ),
    );
  }

  SectionModel? _sectionFromRoute() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is WordManagementArgs ? arguments.section : null;
  }

  List<WordModel> _filterWords(List<WordModel> words) {
    if (_query.isEmpty) {
      return words;
    }

    return words
        .where((word) {
          return word.turkish.toLowerCase().contains(_query) ||
              word.kyrgyz.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.section, required this.word});

  final SectionModel section;
  final WordModel word;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
            child: const Icon(Icons.translate, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.turkish,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(
                    Icons.arrow_downward,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(word.kyrgyz, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
          // IconButton(
          //   tooltip: 'Өзгөртүү',
          //   onPressed: () => _showEditWordDialog(context, section, word),
          //   icon: const Icon(Icons.edit),
          // ),
          IconButton(
            tooltip: 'Өчүрүү',
            onPressed: () => _confirmDeleteWord(context, word),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _WordFormResult {
  const _WordFormResult({required this.turkish, required this.kyrgyz});

  final String turkish;
  final String kyrgyz;
}

// Future<void> _showEditWordDialog(
//   BuildContext context,
//   SectionModel section,
//   WordModel word,
// ) async {
//   final sectionProvider = context.read<SectionProvider>();
//   final result = await showDialog<_WordFormResult>(
//     context: context,
//     builder: (dialogContext) {
//       return _WordFormDialog(word: word);
//     },
//   );

//   if (result == null) {
//     return;
//   }

//   try {
//     final duplicateExists = await sectionProvider.wordTurkishExists(
//       sectionId: section.id,
//       turkish: result.turkish,
//       excludingWordId: word.id,
//     );

//     if (!context.mounted) {
//       return;
//     }

//     if (duplicateExists) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Бул түркчө сөз мурун эле бар.')),
//       );
//       return;
//     }

//     await sectionProvider.updateWord(
//       wordId: word.id,
//       turkish: result.turkish,
//       kyrgyz: result.kyrgyz,
//     );
//   } catch (error) {
//     if (!context.mounted) {
//       return;
//     }

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(error.toString())));
//   }
// }

Future<void> _confirmDeleteWord(BuildContext context, WordModel word) async {
  final sectionProvider = context.read<SectionProvider>();
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Сөздү өчүрүү'),
        content: Text('"${word.turkish}" сөзүн өчүрөсүзбү?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Жокко чыгаруу'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Өчүрүү'),
          ),
        ],
      );
    },
  );

  if (shouldDelete != true) {
    return;
  }

  try {
    await sectionProvider.deleteWord(word.id);
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

class _WordFormDialog extends StatefulWidget {
  const _WordFormDialog({required this.word});

  final WordModel word;

  @override
  State<_WordFormDialog> createState() => _WordFormDialogState();
}

class _WordFormDialogState extends State<_WordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _turkishController;
  late final TextEditingController _kyrgyzController;

  @override
  void initState() {
    super.initState();
    _turkishController = TextEditingController(text: widget.word.turkish);
    _kyrgyzController = TextEditingController(text: widget.word.kyrgyz);
  }

  @override
  void dispose() {
    _turkishController.dispose();
    _kyrgyzController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сөздү өзгөртүү'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _turkishController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Түркчө',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kyrgyzController,
              decoration: const InputDecoration(
                labelText: 'Кыргызча',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Жокко чыгаруу'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Сактоо')),
      ],
    );
  }

  String? _required(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Бул талааны толтуруңуз.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _WordFormResult(
        turkish: _turkishController.text.trim(),
        kyrgyz: _kyrgyzController.text.trim(),
      ),
    );
  }
}
