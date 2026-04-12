import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'views/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: 'https://zdowwkuswwczzwrjcffn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkb3d3a3Vzd3djenp3cmpjZmZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MzI4MDksImV4cCI6MjA5MDIwODgwOX0.-jNrd01Cj2KKBXNX6a_7YkGW0HNwXA86_cpR_V_Jh4s',
  );

  runApp(const WorkNestApp());
}

final supabase = Supabase.instance.client;

class WorkNestApp extends StatelessWidget {
  const WorkNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
