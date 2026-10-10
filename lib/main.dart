import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/section_provider.dart';
import 'providers/user_provider.dart';
import 'screens/admin_screen.dart';
import 'screens/book_reader_screen.dart';
import 'screens/books_screen.dart';
import 'screens/bulk_add_words_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/register_screen.dart';
import 'screens/sections_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/word_management_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/hive_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final hiveService = HiveService();
  await hiveService.initialize();
  runApp(MyApp(hiveService: hiveService));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.hiveService, super.key});

  final HiveService hiveService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<HiveService>.value(value: hiveService),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) =>
              AuthProvider(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) =>
              UserProvider(firestoreService: context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider<SectionProvider>(
          create: (context) => SectionProvider(
            firestoreService: context.read<FirestoreService>(),
            hiveService: context.read<HiveService>(),
          ),
        ),
        ChangeNotifierProvider<GameProvider>(
          create: (context) => GameProvider(
            hiveService: context.read<HiveService>(),
            firestoreService: context.read<FirestoreService>(),
            authService: context.read<AuthService>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          RegisterScreen.routeName: (_) => const RegisterScreen(),
          HomeScreen.routeName: (_) => const MainNavigationScreen(),
          MainNavigationScreen.routeName: (_) => const MainNavigationScreen(),
          BooksScreen.routeName: (_) => const BooksScreen(),
          BookReaderScreen.routeName: (_) => const BookReaderScreen(),
          SectionsScreen.routeName: (_) => const SectionsScreen(),
          AdminScreen.routeName: (_) => const AdminScreen(),
          BulkAddWordsScreen.routeName: (_) => const BulkAddWordsScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          WordManagementScreen.routeName: (_) => const WordManagementScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;

    if (currentUser != null) {
      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}
