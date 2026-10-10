import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'book_reader_screen.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  static const routeName = '/books';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Китептер')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PremiumCard(
              onTap: () {
                Navigator.of(context).pushNamed(BookReaderScreen.routeName);
              },
              child: Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Жарыктар китеби',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
