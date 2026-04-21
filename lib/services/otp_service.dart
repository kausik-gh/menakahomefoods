import 'package:supabase_flutter/supabase_flutter.dart';

class OtpVerificationResult {
  const OtpVerificationResult({
    required this.success,
    required this.isExistingUser,
  });

  final bool success;
  final bool isExistingUser;
}

class OtpService {
  OtpService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> sendOtp(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final response = await _client.functions.invoke(
        'otp-handler',
        body: {'action': 'send', 'email': normalizedEmail},
      );

      if (response.status != 200) {
        throw Exception(
          _extractErrorMessage(
            response.data,
            fallback: 'Could not send OTP. Please try again.',
          ),
        );
      }

      final payload = _asPayload(response.data);
      if (payload['success'] != true) {
        throw Exception(
          _extractErrorMessage(
            response.data,
            fallback: 'Could not send OTP. Please try again.',
          ),
        );
      }
    } on FunctionException catch (e) {
      throw Exception(
        _friendlyFunctionError(e.details, fallback: e.reasonPhrase),
      );
    } catch (e) {
      throw Exception(_friendlyUnknownError(e));
    }
  }

  Future<OtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'otp-handler',
        body: {
          'action': 'verify',
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
        },
      );

      if (response.status != 200) {
        throw Exception(
          _extractErrorMessage(
            response.data,
            fallback: 'Could not verify OTP. Please try again.',
          ),
        );
      }

      final payload = _asPayload(response.data);
      return OtpVerificationResult(
        success: payload['success'] == true,
        isExistingUser: payload['isExistingUser'] == true,
      );
    } on FunctionException catch (e) {
      throw Exception(
        _friendlyFunctionError(e.details, fallback: e.reasonPhrase),
      );
    } catch (e) {
      throw Exception(_friendlyUnknownError(e));
    }
  }

  String _extractErrorMessage(dynamic data, {required String fallback}) {
    final payload = _asPayload(data);
    if (payload['error'] is String) {
      final message = payload['error'] as String;
      return _normalizeMessage(message);
    }
    return fallback;
  }

  Map<String, dynamic> _asPayload(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  String _friendlyFunctionError(dynamic details, {String? fallback}) {
    final mapped = _extractErrorMessage(
      details,
      fallback: fallback ?? 'Network error. Please check your connection.',
    );
    return _normalizeMessage(mapped);
  }

  String _friendlyUnknownError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.toLowerCase().contains('socketexception') ||
        message.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    return _normalizeMessage(message);
  }

  String _normalizeMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('expired')) {
      return 'OTP has expired. Please request a new one.';
    }
    if (lower.contains('invalid otp') || lower.contains('invalid')) {
      return 'Invalid OTP. Please check and try again.';
    }
    if (lower.contains('already used')) {
      return 'This OTP has already been used. Please request a new OTP.';
    }
    if (lower.contains('wait') || lower.contains('seconds')) {
      return message;
    }
    if (lower.contains('failed to send') || lower.contains('could not send')) {
      return 'Unable to send OTP right now. Please try again.';
    }
    if (lower.contains('could not verify') || lower.contains('verification')) {
      return 'Unable to verify OTP right now. Please try again.';
    }
    return message;
  }
}
