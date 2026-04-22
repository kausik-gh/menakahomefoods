import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_snackbar.dart';
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_pressable_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final OtpService _otpService = OtpService();
  late int _step;
  bool _linkSent = false;
  bool _isLoading = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _houseNoCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _houseNoCtrl.dispose();
    _streetCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _animateStep() {
    _slideController.forward(from: 0);
    _fadeController.forward(from: 0);
  }

  Future<void> _sendLink() async {
    if (_isLoading) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      showErrorSnackbar(context, 'Please enter your email');
      return;
    }

    String? errorMessage;
    AuthException? authException;
    setState(() => _isLoading = true);
    try {
      await _otpService.sendOtp(email);
    } on AuthException catch (e) {
      authException = e;
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Something went wrong. Try again.';
      debugPrint('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (!mounted) return;
    if (errorMessage == null) {
      setState(() => _linkSent = true);
      return;
    }

    if (authException != null) {
      debugPrint('OTP Error: ${authException.message}');
      debugPrint('Status: ${authException.statusCode}');
    }
    showErrorSnackbar(context, errorMessage);
  }

  void _checkVerification() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() => _step = 1);
      _animateStep();
    } else {
      showErrorSnackbar(
        context,
        'Email not verified yet.\nPlease click the link in your email first.',
      );
    }
  }

  void _nextFromDetails() {
    if (_nameCtrl.text.trim().isEmpty) {
      showErrorSnackbar(context, 'Enter your name');
      return;
    }
    setState(() => _step = 2);
    _animateStep();
  }

  void _nextFromAddress() {
    if (_houseNoCtrl.text.trim().isEmpty ||
        _streetCtrl.text.trim().isEmpty ||
        _areaCtrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty ||
        _pincodeCtrl.text.trim().isEmpty) {
      showErrorSnackbar(context, 'Please fill all address fields');
      return;
    }
    setState(() => _step = 3);
    _animateStep();
  }

  Future<void> _completeSignup() async {
    final p = _passwordCtrl.text.trim();
    final c = _confirmPasswordCtrl.text.trim();
    if (p.length < 6) {
      showErrorSnackbar(context, 'Password must be at least 6 characters');
      return;
    }
    if (p != c) {
      showErrorSnackbar(context, 'Passwords do not match');
      return;
    }
    String? errorMessage;
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser!;
      await supabase.auth.updateUser(UserAttributes(password: p));
      await supabase.from('users').upsert({
        'id': user.id,
        'auth_id': user.id,
        'email': _emailCtrl.text.trim().toLowerCase(),
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'house_no': _houseNoCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'language': 'en',
        'role': 'customer',
      }, onConflict: 'id');
    } catch (e) {
      errorMessage = 'Sign up failed: ${e.toString()}';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;
    if (errorMessage != null) {
      showErrorSnackbar(context, errorMessage);
      return;
    }
    context.go('/home');
  }

  void _goBack() {
    if (_step == 0 && _linkSent) {
      setState(() => _linkSent = false);
      return;
    }
    if (_step > widget.initialStep) {
      setState(() => _step--);
      _animateStep();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppTheme.primaryDark,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            _buildDots(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildStepBody(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final active = i == _step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppTheme.primary : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return _stepEmail();
      case 1:
        return _stepDetails();
      case 2:
        return _stepAddress();
      case 3:
        return _stepPassword();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepEmail() {
    final email = _emailCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Verification',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _linkSent
              ? 'Check your inbox and click the verification link'
              : "We'll send a verification link to your email",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          enabled: !_linkSent,
          decoration: _inputDecoration('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 20),
        if (!_linkSent)
          AuthPressableButton(
            onTap: _isLoading ? null : _sendLink,
            backgroundColor: AppTheme.primary,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Send Verification Link',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        if (_linkSent) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4A7C59).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFF4A7C59),
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Check your inbox!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF2D5A3D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification link to\n$email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF4A7C59),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Click the link in your email,\nthen tap the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AuthPressableButton(
            onTap: _checkVerification,
            backgroundColor: AppTheme.primary,
            child: Text(
              "I've Verified My Email ✓",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _isLoading ? null : _sendLink,
              child: Text(
                'Resend link',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF4A7C59),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF4A7C59),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _stepPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Password',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePass,
          decoration: _inputDecoration('Password', Icons.lock_outline_rounded)
              .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmPasswordCtrl,
          obscureText: _obscureConfirm,
          decoration:
              _inputDecoration(
                'Confirm Password',
                Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
        ),
        const SizedBox(height: 24),
        AuthPressableButton(
          onTap: _isLoading ? null : _completeSignup,
          backgroundColor: AppTheme.primary,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Complete Sign Up',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _stepDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Details',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          decoration: _inputDecoration(
            'Full name',
            Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(
            'Phone (optional)',
            Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 24),
        AuthPressableButton(
          onTap: _nextFromDetails,
          backgroundColor: AppTheme.primary,
          child: Text(
            'Next',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _stepAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Address',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _houseNoCtrl,
          decoration: _inputDecoration('House No.', Icons.home_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _streetCtrl,
          decoration: _inputDecoration('Street', Icons.signpost_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _areaCtrl,
          decoration: _inputDecoration('Area', Icons.map_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cityCtrl,
          decoration: _inputDecoration('City', Icons.location_city_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pincodeCtrl,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Pincode', Icons.pin_drop_outlined),
        ),
        const SizedBox(height: 24),
        AuthPressableButton(
          onTap: _nextFromAddress,
          backgroundColor: AppTheme.primary,
          child: Text(
            'Next',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
