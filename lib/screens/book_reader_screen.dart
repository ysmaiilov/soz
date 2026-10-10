import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../widgets/app_state_views.dart';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({super.key});

  static const routeName = '/book-reader';

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late final PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset('assets/book.pdf'),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Китеп')),
      body: PdfViewPinch(
        controller: _pdfController,
        scrollDirection: Axis.vertical,
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const LoadingView(message: 'Китеп жүктөлүүдө...'),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, error) {
            return ErrorView(
              message: 'Китепти ачуу мүмкүн болгон жок.\n$error',
            );
          },
        ),
      ),
    );
  }
}
