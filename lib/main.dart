import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_screen.dart';
import 'firebase_options.dart';
import 'navigation/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: FireReminderApp(),
    ),
  );
}

class FireReminderApp extends StatelessWidget {
  const FireReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fire Reminder',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Consumer(
        builder: (context, ref, _) {
          final authState = ref.watch(authControllerProvider);

          return authState.when(
            loading: () => const _SplashLoadingScreen(),
            error: (_, __) => const AuthScreen(), // AuthScreen shows snackbar via listener
            data: (user) {
              if (user == null) return const AuthScreen();
              return const AppShell();
            },
          );
        },
      ),
    );
  }
}

class _SplashLoadingScreen extends StatelessWidget {
  const _SplashLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}