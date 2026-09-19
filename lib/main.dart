import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/clock/clock_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String? token = await ApiService.getToken();
  final bool isLoggedIn = (token != null && token.isNotEmpty);
  final themeProvider = ThemeProvider();

  runApp(
    ThemeProviderScope(
      themeProvider: themeProvider,
      child: WaldoGuardApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class WaldoGuardApp extends StatelessWidget {
  final bool isLoggedIn;

  const WaldoGuardApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProviderScope.of(context);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: isLoggedIn ? const ClockScreen() : const LoginScreen(),
    );
  }
}
