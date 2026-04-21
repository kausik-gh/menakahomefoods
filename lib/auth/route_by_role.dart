import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Routes the signed-in user to admin, rider, or customer home based on email.
Future<void> routeByRole(BuildContext context) async {
  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (context.mounted) context.go('/login');
      return;
    }
    final email = user.email ?? '';

    // Check admin
    final admin = await supabase
        .from('admins')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (admin != null && context.mounted) {
      context.go('/admin');
      return;
    }

    // Check rider
    final rider = await supabase
        .from('riders')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (rider != null && context.mounted) {
      context.go('/rider');
      return;
    }

    // Default: customer
    if (context.mounted) context.go('/home');
  } catch (e) {
    if (context.mounted) context.go('/login');
  }
}
