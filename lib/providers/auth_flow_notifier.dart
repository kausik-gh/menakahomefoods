import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/otp_service.dart';

enum AuthStep { emailInput, otpInput, existingPassword, onboarding }

class AuthFlowNotifier extends ChangeNotifier {
  AuthFlowNotifier({AuthService? authService, OtpService? otpService})
    : _authService = authService ?? AuthService(),
      _otpService = otpService ?? OtpService();

  final AuthService _authService;
  final OtpService _otpService;

  AuthStep _step = AuthStep.emailInput;
  bool _isLoading = false;
  String _email = '';

  AuthStep get step => _step;
  bool get isLoading => _isLoading;
  String get email => _email;

  void setEmail(String email) {
    _email = email.trim().toLowerCase();
    notifyListeners();
  }

  void goToEmailStep() {
    _step = AuthStep.emailInput;
    notifyListeners();
  }

  Future<void> sendOtp() async {
    if (_email.isEmpty) {
      throw Exception('Please enter your email');
    }

    _setLoading(true);
    try {
      await _otpService.sendOtp(_email);
      _step = AuthStep.otpInput;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String otp) async {
    _setLoading(true);
    try {
      final verification = await _otpService.verifyOtp(email: _email, otp: otp);
      if (!verification.success) {
        return false;
      }

      _step = verification.isExistingUser
          ? AuthStep.existingPassword
          : AuthStep.onboarding;
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginExistingUser(String password) async {
    if (password.trim().isEmpty) {
      throw Exception('Please enter your password');
    }

    _setLoading(true);
    try {
      await _authService.signInWithPassword(email: _email, password: password);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerNewUser({
    required String name,
    required String phone,
    required String houseNo,
    required String street,
    required String area,
    required String city,
    required String pincode,
    required String password,
    required String confirmPassword,
  }) async {
    if (name.trim().isEmpty) throw Exception('Name is required');
    if (phone.trim().isEmpty) throw Exception('Phone is required');
    if (houseNo.trim().isEmpty ||
        street.trim().isEmpty ||
        area.trim().isEmpty ||
        city.trim().isEmpty ||
        pincode.trim().isEmpty) {
      throw Exception('Complete address is required');
    }
    if (password.trim().length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (password.trim() != confirmPassword.trim()) {
      throw Exception('Passwords do not match');
    }

    _setLoading(true);
    try {
      final signUpResponse = await _authService.signUpWithPassword(
        email: _email,
        password: password,
      );

      if (signUpResponse.user == null) {
        throw Exception('Could not create account');
      }

      await _authService.saveCustomerProfile(
        name: name,
        phone: phone,
        houseNo: houseNo,
        street: street,
        area: area,
        city: city,
        pincode: pincode,
        language: 'en',
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
