import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const FinancialAgentApp());
}

class FinancialAgentApp extends StatelessWidget {
  const FinancialAgentApp({super.key});

  static const Color primaryBlue = Color(0xFF1548DC);
  static const Color darkBlue = Color(0xFF0D32B2);
  static const Color softBlue = Color(0xFFEBF1FF);
  static const Color bgLight = Color(0xFFF4F7FC);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Origin Financial Copilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: bgLight,
        colorScheme: const ColorScheme.light(
          primary: primaryBlue,
          secondary: darkBlue,
          surface: Colors.white,
          background: bgLight,
          onPrimary: Colors.white,
          onSurface: Color(0xFF1C2434),
        ),
        fontFamily: 'Bricolage Grotesque',
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: primaryBlue.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: primaryBlue.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryBlue,
            side: const BorderSide(color: primaryBlue, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
