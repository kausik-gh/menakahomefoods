import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../auth/route_by_role.dart';
import '../../core/app_snackbar.dart';
import '../../providers/auth_flow_notifier.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_pressable_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.mode});

  final AuthFlowMode mode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _houseNoCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _houseNoCtrl.dispose();
    _streetCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthFlowNotifier(mode: widget.mode),
      child: Consumer<AuthFlowNotifier>(
        builder: (context, authFlow, _) {
          final isSignup = authFlow.mode == AuthFlowMode.signup;
          return Scaffold(
            backgroundColor: const Color(0xFFF5FBF6),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (authFlow.step == AuthStep.emailInput) {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/splash');
                          }
                        } else {
                          authFlow.goToEmailStep();
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Secure Account Access',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSignup
                          ? 'Create your account with email and onboarding details.'
                          : 'Sign in with your email and password.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStepCard(context, authFlow),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, AuthFlowNotifier authFlow) {
    switch (authFlow.step) {
      case AuthStep.emailInput:
        return _buildEmailStep(context, authFlow);
      case AuthStep.passwordInput:
        return _buildExistingPasswordStep(context, authFlow);
      case AuthStep.onboarding:
        return _buildOnboardingStep(context, authFlow);
    }
  }

  Widget _buildEmailStep(BuildContext context, AuthFlowNotifier authFlow) {
    final isSignup = authFlow.mode == AuthFlowMode.signup;
    return _AuthCard(
      title: 'Step 1 - Enter Email',
      child: Column(
        children: [
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email', Icons.email_outlined),
            onChanged: authFlow.setEmail,
          ),
          const SizedBox(height: 16),
          AuthPressableButton(
            onTap: authFlow.isLoading
                ? null
                : () async {
                    try {
                      authFlow.setEmail(_emailCtrl.text);
                      await authFlow.continueFromEmail();
                      if (!context.mounted) return;
                      showInfoSnackbar(
                        context,
                        isSignup
                            ? 'Continue your account setup'
                            : 'Enter your password to continue',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      showErrorSnackbar(
                        context,
                        e.toString().replaceFirst('Exception: ', ''),
                      );
                    }
                  },
            backgroundColor: AppTheme.primary,
            child: authFlow.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget _buildOtpStep(BuildContext context, AuthFlowNotifier authFlow) {
  //   return _AuthCard(
  //     title: 'Step 2 - Verify OTP',
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'OTP sent to ${authFlow.email}',
  //           style: GoogleFonts.poppins(
  //             fontSize: 13,
  //             color: AppTheme.textSecondary,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         TextField(
  //           controller: _otpCtrl,
  //           keyboardType: TextInputType.number,
  //           maxLength: 6,
  //           decoration: _inputDecoration(
  //             '6-digit OTP',
  //             Icons.password_outlined,
  //           ),
  //         ),
  //         AuthPressableButton(
  //           onTap: authFlow.isLoading
  //               ? null
  //               : () async {
  //                   try {
  //                     final isVerified = await authFlow.verifyOtp(
  //                       _otpCtrl.text,
  //                     );
  //                     if (!context.mounted) return;
  //                     if (isVerified) {
  //                       showSuccessSnackbar(
  //                         context,
  //                         'OTP verified successfully',
  //                       );
  //                     } else {
  //                       showErrorSnackbar(context, 'Invalid OTP');
  //                     }
  //                   } catch (e) {
  //                     if (!context.mounted) return;
  //                     showErrorSnackbar(
  //                       context,
  //                       e.toString().replaceFirst('Exception: ', ''),
  //                     );
  //                   }
  //                 },
  //           backgroundColor: AppTheme.primary,
  //           child: authFlow.isLoading
  //               ? const SizedBox(
  //                   width: 22,
  //                   height: 22,
  //                   child: CircularProgressIndicator(
  //                     color: Colors.white,
  //                     strokeWidth: 2.5,
  //                   ),
  //                 )
  //               : Text(
  //                   'Verify OTP',
  //                   style: GoogleFonts.poppins(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //         ),
  //         const SizedBox(height: 10),
  //         TextButton(
  //           onPressed: authFlow.isLoading
  //               ? null
  //               : () async {
  //                   try {
  //                     await authFlow.sendOtp();
  //                     if (!context.mounted) return;
  //                     showInfoSnackbar(context, 'A new OTP was sent');
  //                   } catch (e) {
  //                     if (!context.mounted) return;
  //                     showErrorSnackbar(
  //                       context,
  //                       e.toString().replaceFirst('Exception: ', ''),
  //                     );
  //                   }
  //                 },
  //           child: const Text('Resend OTP'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildExistingPasswordStep(
    BuildContext context,
    AuthFlowNotifier authFlow,
  ) {
    return _AuthCard(
      title: 'Step 2 - Enter Password',
      child: Column(
        children: [
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: _inputDecoration(
              'Password',
              Icons.lock_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),
          AuthPressableButton(
            onTap: authFlow.isLoading
                ? null
                : () async {
                    try {
                      await authFlow.loginExistingUser(_passwordCtrl.text);
                      if (!context.mounted) return;
                      await routeByRole(context);
                    } catch (e) {
                      if (!context.mounted) return;
                      showErrorSnackbar(
                        context,
                        e.toString().replaceFirst('Exception: ', ''),
                      );
                    }
                  },
            backgroundColor: AppTheme.primary,
            child: authFlow.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Log In',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingStep(BuildContext context, AuthFlowNotifier authFlow) {
    return _AuthCard(
      title: 'Step 2 - New User Onboarding',
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: _inputDecoration('Name', Icons.person_outline_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Phone', Icons.phone_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _houseNoCtrl,
            decoration: _inputDecoration('House No', Icons.home_outlined),
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
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordCtrl,
            obscureText: true,
            decoration: _inputDecoration(
              'Password',
              Icons.lock_outline_rounded,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordCtrl,
            obscureText: true,
            decoration: _inputDecoration(
              'Confirm password',
              Icons.lock_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),
          AuthPressableButton(
            onTap: authFlow.isLoading
                ? null
                : () async {
                    try {
                      await authFlow.registerNewUser(
                        name: _nameCtrl.text,
                        phone: _phoneCtrl.text,
                        houseNo: _houseNoCtrl.text,
                        street: _streetCtrl.text,
                        area: _areaCtrl.text,
                        city: _cityCtrl.text,
                        pincode: _pincodeCtrl.text,
                        password: _newPasswordCtrl.text,
                        confirmPassword: _confirmPasswordCtrl.text,
                      );
                      if (!context.mounted) return;
                      context.go('/home');
                    } catch (e) {
                      if (!context.mounted) return;
                      showErrorSnackbar(
                        context,
                        e.toString().replaceFirst('Exception: ', ''),
                      );
                    }
                  },
            backgroundColor: AppTheme.primary,
            child: authFlow.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
