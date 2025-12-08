import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen_neu.dart';
import 'services/einsatz_service_neu.dart';
import 'services/dokumentation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Timer _timer;
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _updateTheme();
    // Check the time every minute to update the theme automatically
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _updateTheme());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTheme() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    // Activate dark mode between 20:00 and 06:29. Light mode starts at 06:30.
    final isDarkMode = hour >= 20 || hour < 6 || (hour == 6 && minute < 30);
    final newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    if (newThemeMode != _themeMode) {
      if (mounted) {
        setState(() {
          _themeMode = newThemeMode;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EinsatzService()),
        ChangeNotifierProvider(create: (_) => DokumentationService()),
      ],
      child: MaterialApp(
        title: 'EinsatzManager',
        theme: ThemeData( // Light Theme
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.red[900],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.red[900],
          ),
        ),
        darkTheme: ThemeData( // Dark Theme
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            brightness: Brightness.dark,
          ),
           appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.red[800],
          ),
          useMaterial3: true,
        ),
        themeMode: _themeMode, // Set the theme mode
        home: const HomeScreenNeu(),
      ),
    );
  }
}