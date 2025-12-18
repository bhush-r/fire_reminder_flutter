import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'navigation/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/auth_controller.dart';


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
      home: Consumer(
        builder: (context, ref, _) {
          final user = ref.watch(authControllerProvider);

          if (user == null) {
            return const AuthScreen();
          }
          return const AppShell();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
