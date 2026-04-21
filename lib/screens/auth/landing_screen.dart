import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FBF6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Image.asset(
                              'assets/images/menaka_logo.png',
                              width: 160,
                              fit: BoxFit.contain,
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(height: 16),
                        Text(
                              'Freshly made. Lovingly delivered.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: const Color(0xFF4A7C59),
                                letterSpacing: 0.3,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              delay: 300.ms,
                              duration: 400.ms,
                            ),
                        const Spacer(flex: 2),
                        Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4A7C59,
                                    ).withValues(alpha: 0.10),
                                    blurRadius: 32,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Welcome',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A2E),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sign in or create your account',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  AnimatedButton(
                                    onPressed: () => context.push('/login'),
                                    filledHighlight: true,
                                    child: Container(
                                      width: double.infinity,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A7C59),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF4A7C59,
                                            ).withValues(alpha: 0.35),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.login_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Log In',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  AnimatedButton(
                                    onPressed: () => context.push('/signup'),
                                    child: Container(
                                      width: double.infinity,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFF4A7C59),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.person_add_outlined,
                                              color: Color(0xFF4A7C59),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Sign Up',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF4A7C59),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Color(0xFFE5E7EB),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'or',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9CA3AF),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Color(0xFFE5E7EB),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: const Color(
                                              0xFF4A7C59,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          '|',
                                          style: TextStyle(
                                            color: Color(0xFFD1D5DB),
                                            fontSize: 16,
                                          ),
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
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: const Color(
                                              0xFF4A7C59,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 450.ms, duration: 500.ms)
                            .slideY(
                              begin: 0.15,
                              end: 0,
                              delay: 450.ms,
                              duration: 500.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const Spacer(),
                        Text(
                          'By continuing you agree to our\n'
                          'Terms of Service & Privacy Policy',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFFB0B7C3),
                            height: 1.6,
                          ),
                        ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filledHighlight = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool filledHighlight;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
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

  Future<void> _animateDown() {
    return _controller.animateTo(
      1,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _animateUp() {
    return _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.elasticOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _animateDown(),
      onTapUp: (_) => _animateUp(),
      onTapCancel: _animateUp,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return Transform.scale(
            scale: 1 - (0.04 * value),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  child!,
                  if (widget.filledHighlight)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12 * value),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
