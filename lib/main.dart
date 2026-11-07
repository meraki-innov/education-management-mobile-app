import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'Pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching themeModeProvider here is what makes the toggle actually
    // work: whenever the sun/moon button in app_shell.dart changes it,
    // THIS widget rebuilds, which rebuilds MaterialApp with the new mode.
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: "EduCare",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const LoginScreen(),
    );
  }
}
