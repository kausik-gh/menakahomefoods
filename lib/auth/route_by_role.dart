import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SignedInRole { admin, rider, customer }

/// Routes the signed-in user to admin, rider, or customer home from `users.role`.
Future<void> routeByRole(BuildContext context) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) {
    if (context.mounted) context.go('/login');
    return;
  }

  final role = await resolveSignedInRole(client: supabase, user: user);
  if (!context.mounted) return;

  switch (role) {
    case SignedInRole.admin:
      context.go('/admin');
      return;
    case SignedInRole.rider:
      context.go('/rider');
      return;
    case SignedInRole.customer:
      context.go('/home');
      return;
  }
}

Future<SignedInRole> resolveSignedInRole({
  SupabaseClient? client,
  User? user,
}) async {
  final supabase = client ?? Supabase.instance.client;
  final authUser = user ?? supabase.auth.currentUser;
  if (authUser == null) {
    throw Exception('No authenticated user found');
  }

  final userId = authUser.id.trim();
  final email = (authUser.email ?? '').trim().toLowerCase();
  Map<String, dynamic>? row;

  try {
    row = await supabase
        .from('users')
        .select('id, auth_id, email, role')
        .eq('auth_id', userId)
        .maybeSingle();
  } catch (_) {}

  if (row == null) {
    try {
      row = await supabase
          .from('users')
          .select('id, auth_id, email, role')
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {}
  }

  if (row == null && email.isNotEmpty) {
    try {
      row = await supabase
          .from('users')
          .select('id, auth_id, email, role')
          .eq('email', email)
          .maybeSingle();
    } catch (_) {}
  }

  if (row != null &&
      (row['auth_id'] == null || '${row['auth_id']}'.trim().isEmpty)) {
    try {
      await supabase.from('users').update({'auth_id': userId}).eq(
        'id',
        row['id'],
      );
    } catch (_) {}
  }

  switch ((row?['role'] as String? ?? 'customer').trim().toLowerCase()) {
    case 'admin':
      return SignedInRole.admin;
    case 'rider':
      return SignedInRole.rider;
    default:
      return SignedInRole.customer;
  }
}
