import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const FinancialAgentApp());
}

class FinancialAgentApp extends StatelessWidget {
  const FinancialAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Origin Financial Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0C0F17),
        colorScheme: const ColorScheme.dark(
          primary: Colors.indigoAccent,
          secondary: Colors.amberAccent,
          surface: Color(0xFF161A26),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121622),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
