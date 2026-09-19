import 'package:flutter/material.dart';
import 'screens/clock_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String? token = await ApiService.getToken();
  final bool isLoggedIn = (token != null && token.isNotEmpty);

  runApp(WaldoGuardApp(isLoggedIn: isLoggedIn));
}

class WaldoGuardApp extends StatelessWidget {
  final bool isLoggedIn;

  const WaldoGuardApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    // WALDO navy blue seed color
    const Color seedColor = Color(0xFF1B2A6B);

    return MaterialApp(
      title: 'WALDO Guard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: isLoggedIn ? const ClockScreen() : const LoginScreen(),
    );
  }
}
