import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _logoMovedToTop = false;
  bool _showAuthContent = false;
  bool _logoCompressed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _logoCompressed = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _logoMovedToTop = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _showAuthContent = true;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final safeAreaTop = mediaQuery.padding.top;
    final initialLogoTop = (screenHeight / 2) - 100;
    final targetLogoTop = safeAreaTop + 18;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FBF6),
      body: Stack(
        children: [
          // Auth content stays in the same screen and fades/slides in.
          AnimatedSlide(
            offset: _showAuthContent ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _showAuthContent ? 1 : 0,
              duration: const Duration(milliseconds: 450),
              child: _buildContent(safeAreaTop, context),
            ),
          ),

          // Logo transitions from center to top and stays as header.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
            top: _logoMovedToTop ? targetLogoTop : initialLogoTop,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                scale: _logoCompressed ? 0.9 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOutCubic,
                  width: _logoMovedToTop ? 150 : 200,
                  child: Image.asset('assets/images/menaka_logo.png'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double safeAreaTop, BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: safeAreaTop + 20),
            // Height reserved for logo after slide
            const SizedBox(height: 120),
            Text(
              'Freshly made. Lovingly delivered.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: const Color(0xFF4A7C59),
              ),
            ),
            const SizedBox(height: 48),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A7C59).withValues(alpha: 0.10),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Already a customer?',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFilledButton(
                    label: 'Log In',
                    icon: Icons.login_rounded,
                    onTap: () => context.push('/login'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'New to Menaka Home Foods?',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildOutlineButton(
                    label: 'Create Account',
                    icon: Icons.person_add_outlined,
                    onTap: () => context.push('/signup'),
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Are you a team member?',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Text(
                          'Admin Login',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A7C59),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF4A7C59),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '|',
                          style: TextStyle(color: Color(0xFFD1D5DB)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Text(
                          'Rider Login',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A7C59),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF4A7C59),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'By continuing you agree to our\nTerms of Service & Privacy Policy',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFFB0B7C3),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _SplashButton(
      onPressed: onTap,
      filled: true,
      label: label,
      icon: icon,
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _SplashButton(
      onPressed: onTap,
      filled: false,
      label: label,
      icon: icon,
    );
  }
}

class _SplashButton extends StatefulWidget {
  const _SplashButton({
    required this.onPressed,
    required this.filled,
    required this.label,
    required this.icon,
  });

  final VoidCallback onPressed;
  final bool filled;
  final String label;
  final IconData icon;

  @override
  State<_SplashButton> createState() => _SplashButtonState();
}

class _SplashButtonState extends State<_SplashButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.animateTo(
        1,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
      ),
      onTapUp: (_) => _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.elasticOut,
      ),
      onTapCancel: () => _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.elasticOut,
      ),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (0.04 * _controller.value),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: widget.filled
                    ? const Color(0xFF4A7C59)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: widget.filled
                    ? null
                    : Border.all(color: const Color(0xFF4A7C59), width: 2),
                boxShadow: widget.filled
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF4A7C59,
                          ).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.filled
                          ? Colors.white
                          : const Color(0xFF4A7C59),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.filled
                            ? Colors.white
                            : const Color(0xFF4A7C59),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
