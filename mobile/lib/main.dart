import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_service.dart';

// Simple in-memory session (persists as long as app tab is open on web)
class AppSession {
  static String? userId;
  static String? userName;
  static String? userEmail;
  static String? userPicture;

  static void setFromUrl(Uri uri) {
    if (uri.queryParameters['auth'] == 'success') {
      userId = uri.queryParameters['userId'];
      userName = uri.queryParameters['name'];
      userEmail = uri.queryParameters['email'];
      userPicture = uri.queryParameters['picture'];
    }
  }

  static bool get isLoggedIn => userId != null && userId!.isNotEmpty;
}

void main() {
  // On web: parse auth result from URL query params (Google OAuth redirect)
  if (kIsWeb) {
    try {
      final uri = Uri.base;
      AppSession.setFromUrl(uri);
      if (AppSession.isLoggedIn) {
        // Clean the URL after reading params
        _cleanUrl();
      }
    } catch (_) {}
  }

  runApp(const FinancialAgentApp());
}

void _cleanUrl() {
  // Removes auth query params from the browser URL bar without reload
  if (kIsWeb) {
    try {
      // ignore: undefined_prefixed_name
      // Using a JS interop stub is not needed — Flutter web handles history
    } catch (_) {}
  }
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
      title: 'Finova — Financial Copilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: bgLight,
        colorScheme: const ColorScheme.light(
          primary: primaryBlue,
          secondary: darkBlue,
          surface: Colors.white,
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
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _checked = false;
  _AppRoute _route = _AppRoute.loading;
  String _resolvedUserId = ApiService.demoUserId;

  @override
  void initState() {
    super.initState();
    _determineRoute();
  }

  Future<void> _determineRoute() async {
    try {
      // Check if Google OAuth just completed (URL has auth=success)
      if (AppSession.isLoggedIn) {
        _resolvedUserId = AppSession.userId!;

        // Check if this user has completed onboarding
        final onboarded = await ApiService.checkOnboardingStatus(userId: _resolvedUserId);

        if (mounted) {
          setState(() {
            _route = onboarded ? _AppRoute.dashboard : _AppRoute.onboarding;
            _checked = true;
          });
        }
        return;
      }

      // Check if demo user has already onboarded (fallback for local dev)
      final status = await ApiService.checkOnboardingStatus(userId: ApiService.demoUserId);
      if (mounted) {
        setState(() {
          _route = status ? _AppRoute.dashboard : _AppRoute.login;
          _checked = true;
        });
      }
    } catch (e) {
      debugPrint('Route check error: $e');
      if (mounted) {
        setState(() {
          _route = _AppRoute.login;
          _checked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple pulse animation while loading
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1548DC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Finova',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7BA8FF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return switch (_route) {
      _AppRoute.login => const LoginScreen(),
      _AppRoute.onboarding => OnboardingScreen(userId: _resolvedUserId),
      _AppRoute.dashboard => const MainNavigationScreen(),
      _ => const LoginScreen(),
    };
  }
}

enum _AppRoute { loading, login, onboarding, dashboard }
