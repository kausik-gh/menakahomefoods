import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Holds the logged-in customer's row from `customers` for reuse across screens.
class CustomerProfileNotifier extends ChangeNotifier {
  Map<String, dynamic>? customer;
  bool loading = false;
  String? errorMessage;

  Future<void> loadFromSupabase() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      customer = null;
      notifyListeners();
      return;
    }
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final row = await Supabase.instance.client
          .from('customers')
          .select()
          .eq('id', uid)
          .maybeSingle();
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
