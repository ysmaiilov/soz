import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/section_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/section_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_state_views.dart';
import '../widgets/premium_widgets.dart';
import 'word_management_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  static const routeName = '/admin';

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ панели'),
        // actions: [
        //   TextButton(
        //     onPressed: () => _createDefaultData(context),
        //     child: const Text('Баштапкы маалыматтарды түзүү'),
        //   ),
        // ],
      ),
      body: firebaseUser == null
          ? const _AccessDenied()
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
                if (user?.isAdmin != true) {
                  return const _AccessDenied();
                }

                return const _AdminSectionsView();
              },
            ),
    );
  }
}

class _AdminSectionsView extends StatelessWidget {
  const _AdminSectionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            itemCount: sections.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final section = sections[index];
              return _SectionAdminTile(section: section);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSectionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Бөлүм түзүү'),
      ),
    );
  }
}

class _SectionAdminTile extends StatelessWidget {
  const _SectionAdminTile({required this.section});

  final SectionModel section;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
            child: const Icon(Icons.folder_open, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Тартиби: ${section.order}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Сөздөрдү башкаруу',
            onPressed: () {
              Navigator.of(context).pushNamed(
                WordManagementScreen.routeName,
                arguments: WordManagementArgs(section: section),
              );
            },
            icon: const Icon(Icons.library_books),
          ),
          IconButton(
            tooltip: 'Өзгөртүү',
            onPressed: () => _showSectionDialog(context, section: section),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Өчүрүү',
            onPressed: () => _confirmDelete(context, section),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: AppColors.wrong),
            const SizedBox(height: 12),
            Text(
              'Кирүүгө уруксат жок',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Артка'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionFormResult {
  const _SectionFormResult({required this.title, required this.order});

  final String title;
  final int order;
}

Future<void> _showSectionDialog(
  BuildContext context, {
  SectionModel? section,
}) async {
  final sectionProvider = context.read<SectionProvider>();
  final result = await showDialog<_SectionFormResult>(
    context: context,
    builder: (dialogContext) {
      return _SectionFormDialog(section: section);
    },
  );

  if (result == null) {
    return;
  }

  try {
    if (section == null) {
      await sectionProvider.createSection(
        title: result.title,
        order: result.order,
      );
    } else {
      await sectionProvider.updateSection(
        sectionId: section.id,
        title: result.title,
        order: result.order,
      );
    }
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

// Future<void> _createDefaultData(BuildContext context) async {
//   final sectionProvider = context.read<SectionProvider>();

//   try {
//     final result = await sectionProvider.createDefaultDataIfEmpty();
//     if (!context.mounted) {
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           result.created
//               ? 'Баштапкы маалыматтар түзүлдү.'
//               : 'Маалымат базасы бош эмес. Баштапкы маалыматтар түзүлгөн жок.',
//         ),
//       ),
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

Future<void> _confirmDelete(BuildContext context, SectionModel section) async {
  final sectionProvider = context.read<SectionProvider>();
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Бөлүмдү өчүрүү'),
        content: Text('"${section.title}" бөлүмүн өчүрөсүзбү?'),
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
    await sectionProvider.deleteSection(section.id);
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

class _SectionFormDialog extends StatefulWidget {
  const _SectionFormDialog({this.section});

  final SectionModel? section;

  @override
  State<_SectionFormDialog> createState() => _SectionFormDialogState();
}

class _SectionFormDialogState extends State<_SectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _orderController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section?.title ?? '');
    _orderController = TextEditingController(
      text: widget.section?.order.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.section != null;

    return AlertDialog(
      title: Text(isEditing ? 'Бөлүмдү өзгөртүү' : 'Бөлүм түзүү'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Аталышы',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Аталышын киргизиңиз.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Тартиби',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final order = int.tryParse(value?.trim() ?? '');
                if (order == null) {
                  return 'Тартиби сан болушу керек.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Жокко чыгаруу'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Сактоо' : 'Түзүү'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _SectionFormResult(
        title: _titleController.text.trim(),
        order: int.parse(_orderController.text.trim()),
      ),
    );
  }
}
