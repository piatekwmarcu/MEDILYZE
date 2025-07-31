import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medilyze/screens/login_page.dart';
import '../../screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Supabase.initialize(
    url: 'https://yawjwsxxgxcfnzwmupjk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhd2p3c3h4Z3hjZm56d211cGprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxMDQxNTYsImV4cCI6MjA2ODY4MDE1Nn0.03Ng5FuEJzKAJt8rX6dAdd8-jqEMUz8uhFF4kBA7EwU',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediLyze',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE6FDFF),
        primaryColor: const Color(0xFFA5668B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA5668B),
          background: const Color(0xFFE6FDFF),
          primary: const Color(0xFFA5668B),
          secondary: const Color(0xFF4E6E58),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA5668B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          fillColor: Colors.white,
          filled: true,
        ),
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}
