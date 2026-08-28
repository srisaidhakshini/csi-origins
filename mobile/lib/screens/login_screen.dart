import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _signInWithGoogle() {
    setState(() => _isLoading = true);
    AudioService.openUrl('${ApiService.baseUrl}/auth/google/login?state=new_user');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),

                        // Logo + Brand
                        Row(
                          children: [
                            _FinovaLogoSvg(size: 44),
                            const SizedBox(width: 12),
                            const Text(
                              'Finova',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1548DC).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF1548DC).withOpacity(0.4)),
                              ),
                              child: const Text(
                                'BETA',
                                style: TextStyle(
                                  color: Color(0xFF7BA8FF),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Hero illustration
                        Center(child: _HeroIllustration()),
                        const SizedBox(height: 40),

                        // Headline
                        const Text(
                          'Your money,\nalways one step\nahead.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Finova reads your bank SMS and Gmail alerts to build a live financial picture — and acts before problems hit.',
                          style: TextStyle(
                            color: Color(0xFF8BA3C7),
                            fontSize: 14.5,
                            height: 1.55,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Feature pills
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _FeaturePill(svg: _svgShield, label: 'Bank-grade privacy'),
                            _FeaturePill(svg: _svgBolt, label: 'Real-time alerts'),
                            _FeaturePill(svg: _svgBrain, label: 'AI causal engine'),
                          ],
                        ),

                        const Spacer(),
                        const SizedBox(height: 32),

                        // Google Sign In Button
                        GestureDetector(
                          onTap: _isLoading ? null : _signInWithGoogle,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _isLoading ? const Color(0xFF1A2A40) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFF1548DC),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.string(_svgGoogleG, width: 22, height: 22),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          color: Color(0xFF1C2434),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            'By continuing, you agree to our Terms & Privacy Policy.\nWe never store passwords.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF8BA3C7).withOpacity(0.7),
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SVG Strings ──────────────────────────────────────────────────────────────

const String _svgGoogleG = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

const String _svgShield = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#7BA8FF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
</svg>
''';

const String _svgBolt = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#7BA8FF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
</svg>
''';

const String _svgBrain = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#7BA8FF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96-.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24A2.5 2.5 0 0 1 9.5 2Z"/>
  <path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96-.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24A2.5 2.5 0 0 0 14.5 2Z"/>
</svg>
''';

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FinovaLogoSvg extends StatelessWidget {
  final double size;
  const _FinovaLogoSvg({required this.size});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
        <rect width="44" height="44" rx="12" fill="#1548DC"/>
        <path d="M10 22 L18 14 L26 22 L34 14" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        <path d="M10 30 L18 22 L26 30 L34 22" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none" opacity="0.5"/>
        <circle cx="18" cy="22" r="2.5" fill="white"/>
        <circle cx="26" cy="22" r="2.5" fill="white" opacity="0.7"/>
      </svg>
      ''',
      width: size,
      height: size,
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 200">
        <!-- Background glow -->
        <ellipse cx="150" cy="140" rx="120" ry="40" fill="#1548DC" opacity="0.08"/>

        <!-- Phone body -->
        <rect x="95" y="20" width="110" height="170" rx="16" fill="#0D1F3C"/>
        <rect x="99" y="24" width="102" height="162" rx="13" fill="#152844"/>

        <!-- Screen content -->
        <rect x="108" y="38" width="84" height="12" rx="4" fill="#1548DC" opacity="0.7"/>
        <rect x="108" y="58" width="50" height="8" rx="3" fill="#1E3A6E"/>
        <rect x="164" y="58" width="28" height="8" rx="3" fill="#1548DC" opacity="0.5"/>
        <rect x="108" y="74" width="84" height="1" fill="#1E3A6E"/>

        <!-- Transaction rows -->
        <circle cx="117" cy="92" r="7" fill="#1548DC" opacity="0.3"/>
        <rect x="130" y="88" width="40" height="5" rx="2" fill="#2A4A7F"/>
        <rect x="130" y="96" width="24" height="4" rx="2" fill="#1E3A6E"/>
        <rect x="170" y="88" width="22" height="9" rx="3" fill="#22C55E" opacity="0.2"/>

        <circle cx="117" cy="115" r="7" fill="#FF5252" opacity="0.3"/>
        <rect x="130" y="111" width="35" height="5" rx="2" fill="#2A4A7F"/>
        <rect x="130" y="119" width="20" height="4" rx="2" fill="#1E3A6E"/>
        <rect x="170" y="111" width="22" height="9" rx="3" fill="#FF5252" opacity="0.2"/>

        <circle cx="117" cy="138" r="7" fill="#1548DC" opacity="0.3"/>
        <rect x="130" y="134" width="44" height="5" rx="2" fill="#2A4A7F"/>
        <rect x="130" y="142" width="28" height="4" rx="2" fill="#1E3A6E"/>
        <rect x="170" y="134" width="22" height="9" rx="3" fill="#22C55E" opacity="0.2"/>

        <!-- AI badge floating -->
        <rect x="170" y="8" width="64" height="28" rx="10" fill="#1548DC"/>
        <circle cx="184" cy="22" r="6" fill="white" opacity="0.15"/>
        <text x="192" y="26" font-family="sans-serif" font-size="9" font-weight="bold" fill="white">AI ALERT</text>

        <!-- Connecting line -->
        <path d="M 170 22 Q 155 30 155 40" stroke="#1548DC" stroke-width="1.5" stroke-dasharray="3,3" fill="none"/>

        <!-- Left floating card -->
        <rect x="14" y="60" width="76" height="48" rx="10" fill="#0D1F3C"/>
        <rect x="18" y="65" width="30" height="6" rx="3" fill="#1548DC" opacity="0.6"/>
        <rect x="18" y="75" width="50" height="14" rx="4" fill="#1548DC" opacity="0.15"/>
        <text x="21" y="87" font-family="sans-serif" font-size="10" font-weight="bold" fill="#7BA8FF">₹35K</text>
        <rect x="18" y="95" width="40" height="5" rx="2" fill="#1E3A6E"/>
        <path d="M 90 84 L 99 84" stroke="#1548DC" stroke-width="1.5" stroke-dasharray="2,2"/>

        <!-- Right floating card -->
        <rect x="210" y="90" width="76" height="48" rx="10" fill="#0D1F3C"/>
        <rect x="214" y="95" width="30" height="6" rx="3" fill="#FF5252" opacity="0.6"/>
        <rect x="214" y="105" width="50" height="14" rx="4" fill="#FF5252" opacity="0.1"/>
        <text x="217" y="117" font-family="sans-serif" font-size="10" font-weight="bold" fill="#FF8A8A">RISK</text>
        <rect x="214" y="125" width="35" height="5" rx="2" fill="#1E3A6E"/>
        <path d="M 205 114 L 210 114" stroke="#FF5252" stroke-width="1.5" stroke-dasharray="2,2"/>
      </svg>
      ''',
      width: 280,
      height: 200,
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String svg;
  final String label;
  const _FeaturePill({required this.svg, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3C),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF1E3A6E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(svg, width: 14, height: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8BA3C7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
