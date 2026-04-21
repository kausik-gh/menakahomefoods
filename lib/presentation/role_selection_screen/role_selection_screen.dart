import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Landing only: `/` — log in / sign up entry. Do not use elsewhere.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Column(
                          children: [
                            _buildLogo()
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1, 1),
                                  duration: 500.ms,
                                  curve: Curves.elasticOut,
                                ),
                            const SizedBox(height: 12),
                            Text(
                              'Freshly made. Lovingly delivered.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: const Color(0xFF4A7C59),
                                letterSpacing: 0.3,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 400.ms)
                                .slideY(
                                  begin: 0.3,
                                  end: 0,
                                  delay: 200.ms,
                                  duration: 400.ms,
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildCard(context)
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 500.ms)
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            delay: 350.ms,
                            duration: 500.ms,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: 24),
                      Text(
                        'By continuing you agree to our\n'
                        'Terms of Service & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFFB0B7C3),
                          fontFamily: 'Poppins',
                          height: 1.6,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 400.ms),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// PNG has alpha so it blends with [Scaffold] background `0xFFF5FBF6`.
  Widget _buildLogo() {
    return Image.asset(
      'assets/images/menaka_logo.png',
      width: 140,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      semanticLabel: 'Menaka Home Foods logo',
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A7C59).withValues(alpha: 0.10),
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
          const Text(
            'Welcome',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sign in or create your account',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
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
                    color: const Color(0xFF4A7C59).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Log In',
                      style: TextStyle(
                        fontFamily: 'Poppins',
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
            filledHighlight: false,
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
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      color: Color(0xFF4A7C59),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A7C59),
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
                padding: EdgeInsets.symmetric(horizontal: 12),
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
          const Text(
            'Are you a team member?',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => context.push('/login'),
                child: const Text(
                  'Admin Login',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A7C59),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF4A7C59),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
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
                child: const Text(
                  'Rider Login',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A7C59),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF4A7C59),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Press scale + optional white flash on the filled primary button (landing only).
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
  late final AnimationController _pressCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Future<void> _animateDown() {
    return _pressCtrl.animateTo(
      1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  Future<void> _animateUp() {
    return _pressCtrl.animateTo(
      0.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.elasticOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _animateDown(),
      onTapCancel: () => _animateUp(),
      onTap: () async {
        await _animateUp();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) {
          final v = _pressCtrl.value;
          final scale = 1.0 - 0.04 * v;
          return Transform.scale(
            scale: scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  child!,
                  if (widget.filledHighlight)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12 * v),
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
