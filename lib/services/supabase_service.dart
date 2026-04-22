import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  /// Supabase is initialized in [main] via [Supabase.initialize].
  SupabaseClient get client => Supabase.instance.client;
  String? lastSubscriptionError;

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
    double discount = 0,
    String? couponCode,
    required double total,
    String paymentMethod = 'gpay',
    String paymentStatus = 'paid',
  }) async {
    try {
      final normalizedItems = items
          .map(
            (item) => {
              'dish_id': item['dish_id'],
              'name': '${item['name'] ?? ''}'.trim(),
              'price': (item['price'] as num?)?.toDouble() ?? 0,
              'quantity':
                  ((item['quantity'] as num?) ?? (item['qty'] as num?) ?? 1)
                      .toInt(),
              'qty':
                  ((item['qty'] as num?) ?? (item['quantity'] as num?) ?? 1)
                      .toInt(),
            },
          )
          .toList();
      final response = await client
          .from('orders')
          .upsert({
            'customer_id': customerId,
            'customer_name': customerName.trim(),
            'customer_phone': customerPhone.trim(),
            'customer_address': customerAddress.trim(),
            'items': normalizedItems,
            'order_type': orderType.trim(),
            'meal': meal.trim(),
            'status': 'placed',
            'picked': false,
            'subtotal': subtotal,
            'delivery_fee': deliveryFee,
            'gst': gst,
            'discount': discount,
            'coupon_code': (couponCode ?? '').trim(),
            'total': total,
            'payment_method': paymentMethod.trim(),
            'payment_status': paymentStatus.trim(),
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
    lastSubscriptionError = null;
    try {
      final response = await client
          .from('subscriptions')
          .upsert({
            'customer_id': customerId,
            'customer_name': customerName.trim(),
            'customer_phone': customerPhone.trim(),
            'start_date': startDate.toIso8601String().split('T').first,
            'end_date': endDate.toIso8601String().split('T').first,
            'meals': meals.map((meal) => meal.trim()).where((meal) => meal.isNotEmpty).toList(),
            'weekly_plan': weeklyPlan,
            'status': 'active',
            'total_amount': totalAmount,
            'payment_method': 'gpay',
            'payment_status': 'pending',
          })
          .select('id')
          .single();
      return response['id'] as String?;
    } catch (e) {
      lastSubscriptionError = 'Supabase insert failed for `public.subscriptions`: $e';
      return null;
    }
  }

  Future<Map<String, dynamic>?> getActiveSubscription(String customerId) async {
    try {
      if (customerId.trim().isEmpty) {
        return null;
      }
      final response = await client
          .from('subscriptions')
          .select()
          .eq('customer_id', customerId.trim())
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
      if (customerId.trim().isEmpty) {
        return [];
      }
      final response = await client
          .from('subscriptions')
          .select()
          .eq('customer_id', customerId.trim())
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
