import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );
  }

  Future<void> saveCustomerProfile({
    required String name,
    required String phone,
    required String houseNo,
    required String street,
    required String area,
    required String city,
    required String pincode,
    required String language,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final res = await _client.from('customers').insert({
        'id': user.id,
        'name': name.trim(),
        'phone': phone.trim(),
        'house_no': houseNo.trim(),
        'street': street.trim(),
        'area': area.trim(),
        'city': city.trim(),
        'pincode': pincode.trim(),
        'language': language.trim(),
      }).select();
      // Debug tip: keeps exact insert output visible during dev troubleshooting.
      // ignore: avoid_print
      print(res);
    } catch (e) {
      // Debug tip: print exact PostgREST/DB error.
      // ignore: avoid_print
      print(e);
      rethrow;
    }
  }
}
