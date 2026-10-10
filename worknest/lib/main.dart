import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'views/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await AppTheme.loadThemeMode();

  runApp(const WorkNestApp());
}

final supabase = Supabase.instance.client;

class WorkNestApp extends StatelessWidget {
  const WorkNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (_, mode, __) => MaterialApp(
        title: 'WorkNest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeFor(false),
        darkTheme: AppTheme.themeFor(true),
        themeMode: mode,
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          if (dark != AppTheme.isDark) {
            AppTheme.isDark = dark;
            // Screens read AppTheme colours directly, so repaint everything once
            // (keeps navigation and screen state)
            WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildAll(context));
          }
          return child!;
        },
        home: const SplashScreen(),
      ),
    );
  }

  static void _rebuildAll(BuildContext context) {
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }
    if (context.mounted) (context as Element).visitChildren(rebuild);
  }
}
