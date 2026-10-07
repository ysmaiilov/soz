import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/section_model.dart';
import '../providers/section_provider.dart';
// import '../utils/app_theme.dart';
import '../widgets/app_state_views.dart';
import '../widgets/premium_widgets.dart';

class BulkAddWordsArgs {
  const BulkAddWordsArgs({
    required this.section,
    this.returnToWordManagement = false,
  });

  final SectionModel section;
  final bool returnToWordManagement;
}

class BulkAddWordsScreen extends StatefulWidget {
  const BulkAddWordsScreen({super.key});

  static const routeName = '/admin/bulk-add-words';

  @override
  State<BulkAddWordsScreen> createState() => _BulkAddWordsScreenState();
}

class _BulkAddWordsScreenState extends State<BulkAddWordsScreen> {
  final _wordsController = TextEditingController();
  SectionModel? _selectedSection;
  bool _returnToWordManagement = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArgs = _argsFromRoute();
    _selectedSection ??= routeArgs?.section;
    _returnToWordManagement = routeArgs?.returnToWordManagement ?? false;
  }

  @override
  void dispose() {
    _wordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сөздөрдү кошуу')),
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
            return const EmptyView(message: 'Жеткиликтүү бөлүмдөр жок.');
          }

          _syncSelectedSection(sections);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                const ScreenHeader(
                  icon: Icons.playlist_add,
                  title: 'Сөздөрдү кошуу',
                  subtitle: 'Ар бир сап жаңы сөз болуп эсептелет.',
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Бөлүмдү тандаңыз',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedSection?.id,
                          decoration: const InputDecoration(
                            labelText: 'Бөлүм',
                            prefixIcon: Icon(Icons.folder_open),
                          ),
                          items: sections
                              .map(
                                (section) => DropdownMenuItem<String>(
                                  value: section.id,
                                  child: Text(section.title),
                                ),
                              )
                              .toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;

                                  setState(() {
                                    _selectedSection = sections.firstWhere(
                                      (e) => e.id == value,
                                    );
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Сөздөрдүн тизмеси',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Ар бир сап төмөнкү форматта болушу керек:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'ev=үй\n'
                            'kapı=эшик\n'
                            'masa=үстөл\n'
                            'kitap=китеп',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        TextField(
                          controller: _wordsController,
                          enabled: !_isSaving,
                          minLines: 14,
                          maxLines: 20,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            alignLabelWithHint: true,
                            labelText: 'Сөздөрдү ушул жерге жазыңыз',
                            prefixIcon: Icon(Icons.edit_note),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _wordsController,
                          builder: (context, value, _) {
                            final lines = value.text
                                .split('\n')
                                .where((e) => e.trim().isNotEmpty)
                                .length;

                            return Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Киргизилген саптар: $lines',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveWords,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      _isSaving ? 'Сакталууда...' : 'Сөздөрдү сактоо',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  BulkAddWordsArgs? _argsFromRoute() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is BulkAddWordsArgs ? arguments : null;
  }

  void _syncSelectedSection(List<SectionModel> sections) {
    final selectedSection = _selectedSection;
    if (selectedSection != null &&
        sections.any((section) => section.id == selectedSection.id)) {
      _selectedSection = sections.firstWhere(
        (section) => section.id == selectedSection.id,
      );
      return;
    }

    _selectedSection = sections.first;
  }

  Future<void> _saveWords() async {
    final section = _selectedSection;
    if (section == null) {
      setState(() {
        _errorMessage = 'Бөлүмдү тандаңыз.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final sectionProvider = context.read<SectionProvider>();

    try {
      final result = await sectionProvider.bulkAddWords(
        sectionId: section.id,
        input: _wordsController.text,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Сөздөр кошулду'),
            content: Text(
              'Кошулду: ${result.added}\n'
              'Өткөрүлдү: ${result.skipped}\n'
              'Кайталанган сөздөр: ${result.duplicates}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Макул'),
              ),
            ],
          );
        },
      );

      _wordsController.clear();
      if (_returnToWordManagement && mounted) {
        Navigator.of(context).pop();
      }
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
          _isSaving = false;
        });
      }
    }
  }
}
