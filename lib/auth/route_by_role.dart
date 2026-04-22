import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SignedInRole { admin, rider, customer }

/// Routes the signed-in user to admin, rider, or customer home based on email.
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

  final userId = authUser.id;
  final email = (authUser.email ?? '').trim().toLowerCase();

  if (await _hasAdminRecord(supabase, email: email)) {
    return SignedInRole.admin;
  }

  if (await _hasRoleRecord(supabase, table: 'riders', userId: userId, email: email)) {
    return SignedInRole.rider;
  }

  return SignedInRole.customer;
}

Future<bool> _hasAdminRecord(
  SupabaseClient client, {
  required String email,
}) async {
  if (email.isEmpty) {
    return false;
  }

  try {
    final isAdmin = await client.rpc(
      'is_admin_email',
      params: {'p_email': email},
    );
    return isAdmin == true;
  } catch (_) {
    return false;
  }
}

Future<bool> _hasRoleRecord(
  SupabaseClient client, {
  required String table,
  required String userId,
  required String email,
}) async {
  try {
    final byId = await client.from(table).select('id').eq('id', userId).maybeSingle();
    if (byId != null) {
      return true;
    }
  } catch (_) {
    // Ignore and continue to email-based lookup.
  }

  if (email.isEmpty) {
    return false;
  }

  try {
    final byEmail = await client.from(table).select('id').eq('email', email).maybeSingle();
    return byEmail != null;
  } catch (_) {
    // If role lookup is blocked or the column is unavailable, fall back gracefully.
    return false;
  }
}
