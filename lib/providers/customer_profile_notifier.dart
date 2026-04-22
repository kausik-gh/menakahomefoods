import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Holds the logged-in user's row from `users` for reuse across screens.
class CustomerProfileNotifier extends ChangeNotifier {
  Map<String, dynamic>? customer;
  bool loading = false;
  String? errorMessage;

  Future<void> loadFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    final uid = user?.id;
    final email = user?.email?.trim().toLowerCase() ?? '';
    if (uid == null) {
      customer = null;
      notifyListeners();
      return;
    }
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      Map<String, dynamic>? row;

      try {
        row = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', uid)
            .maybeSingle();
      } catch (_) {}

      if (row == null) {
        try {
          row = await Supabase.instance.client
              .from('users')
              .select()
              .eq('auth_id', uid)
              .maybeSingle();
        } catch (_) {}
      }

      if (row == null && email.isNotEmpty) {
        try {
          row = await Supabase.instance.client
              .from('users')
              .select()
              .eq('email', email)
              .maybeSingle();
        } catch (_) {}
      }

      if (row != null &&
          (row['auth_id'] == null || '${row['auth_id']}'.trim().isEmpty)) {
        try {
          await Supabase.instance.client
              .from('users')
              .update({'auth_id': uid})
              .eq('id', row['id']);
          row['auth_id'] = uid;
        } catch (_) {}
      }

      customer = row;
    } catch (e) {
      errorMessage = e.toString();
      customer = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    customer = null;
    errorMessage = null;
    notifyListeners();
  }

  String? get customerId => customer?['id'] as String?;
  String get role => (customer?['role'] as String? ?? 'customer').trim().toLowerCase();

  String formattedAddress() {
    final c = customer;
    if (c == null) return '';
    final parts =
        [c['house_no'], c['street'], c['area'], c['city'], c['pincode']]
            .where((e) => e != null && '$e'.trim().isNotEmpty)
            .map((e) => '$e')
            .toList();
    return parts.join(', ');
  }
}
