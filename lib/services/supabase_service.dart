import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  /// Supabase is initialized in [main] via [Supabase.initialize].
  SupabaseClient get client => Supabase.instance.client;

  // Save order to Supabase
  Future<String?> saveOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required List<Map<String, dynamic>> items,
    required String orderType,
    required String meal,
    required double subtotal,
    required double deliveryFee,
    required double gst,
    required double total,
  }) async {
    try {
      final response = await client
          .from('orders')
          .insert({
            'customer_id': customerId,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'customer_address': customerAddress,
            'items': items,
            'order_type': orderType,
            'meal': meal,
            'status': 'placed',
            'subtotal': subtotal,
            'delivery_fee': deliveryFee,
            'gst': gst,
            'total': total,
          })
          .select('id')
          .single();
      return response['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Fetch orders for a customer
  Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId,
  ) async {
    try {
      final response = await client
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Real-time order status subscription
  RealtimeChannel subscribeToOrder(
    String orderId,
    Function(Map<String, dynamic>) onUpdate,
  ) {
    return client
        .channel('order_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  // ─── Subscription Methods ─────────────────────────────────────────────────

  Future<String?> saveSubscription({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> meals,
    required Map<String, dynamic> weeklyPlan,
    required double totalAmount,
  }) async {
    try {
      final response = await client
          .from('subscriptions')
          .insert({
            'customer_id': customerId,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'start_date': startDate.toIso8601String().split('T').first,
            'end_date': endDate.toIso8601String().split('T').first,
            'meals': meals,
            'weekly_plan': weeklyPlan,
            'status': 'active',
            'total_amount': totalAmount,
          })
          .select('id')
          .single();
      return response['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getActiveSubscription(String customerId) async {
    try {
      final response = await client
          .from('subscriptions')
          .select()
          .eq('customer_id', customerId)
          .inFilter('status', ['active', 'paused'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllSubscriptions(
    String customerId,
  ) async {
    try {
      final response = await client
          .from('subscriptions')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateSubscriptionStatus(
    String subscriptionId,
    String status,
  ) async {
    try {
      await client
          .from('subscriptions')
          .update({'status': status})
          .eq('id', subscriptionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateWeeklyPlan(
    String subscriptionId,
    Map<String, dynamic> weeklyPlan,
  ) async {
    try {
      await client
          .from('subscriptions')
          .update({'weekly_plan': weeklyPlan})
          .eq('id', subscriptionId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
