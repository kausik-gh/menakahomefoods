import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String menuItemImageBucket = 'menu-item-images';
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  /// Supabase is initialized in [main] via [Supabase.initialize].
  SupabaseClient get client => Supabase.instance.client;
  String? lastSubscriptionError;

  Future<List<Map<String, dynamic>>> getMenuItems() async {
    try {
      final response = await client
          .from('menu_items')
          .select()
          .order('meal_type')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<String> uploadMenuItemImage({
    required String itemId,
    required Uint8List bytes,
    required String originalFileName,
    String? contentType,
  }) async {
    final trimmedName = originalFileName.trim();
    final extension = trimmedName.contains('.')
        ? trimmedName.split('.').last.toLowerCase()
        : 'jpg';
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final filePath =
        '$itemId/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await client.storage
        .from(menuItemImageBucket)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: contentType,
          ),
        );

    return client.storage.from(menuItemImageBucket).getPublicUrl(filePath);
  }

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
              'qty': ((item['qty'] as num?) ?? (item['quantity'] as num?) ?? 1)
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
            'order_date': DateTime.now().toIso8601String().split('T').first,
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
            'meals': meals
                .map((meal) => meal.trim())
                .where((meal) => meal.isNotEmpty)
                .toList(),
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
      lastSubscriptionError =
          'Supabase insert failed for `public.subscriptions`: $e';
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

  Future<SubscriptionOrderGenerationResult> generateTomorrowSubscriptionOrders({
    DateTime? referenceTime,
  }) async {
    final now = (referenceTime ?? DateTime.now()).toLocal();
    final targetDate = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    final targetDateKey = _dateKey(targetDate);
    final targetDayKey = _dayKey(targetDate);

    final subscriptionsResponse = await client
        .from('subscriptions')
        .select()
        .eq('status', 'active')
        .lte('start_date', targetDateKey)
        .gte('end_date', targetDateKey);

    final subscriptions = List<Map<String, dynamic>>.from(subscriptionsResponse);
    final plannedRows = <_PlannedSubscriptionOrder>[];
    final menuItemIds = <String>{};

    for (final subscription in subscriptions) {
      final meals = _stringListFromDynamic(subscription['meals']);
      final weeklyPlan = _mapFromDynamic(subscription['weekly_plan']);
      final dayPlan = _mapFromDynamic(weeklyPlan[targetDayKey]);
      final customerId = '${subscription['customer_id'] ?? ''}'.trim();

      if (customerId.isEmpty) continue;

      for (final meal in meals) {
        if (!_allowedSubscriptionMeals.contains(meal)) continue;
        final rawMenuItemId = '${dayPlan[meal] ?? ''}'.trim();
        if (rawMenuItemId.isEmpty) continue;

        plannedRows.add(
          _PlannedSubscriptionOrder(
            customerId: customerId,
            customerName: '${subscription['customer_name'] ?? ''}'.trim(),
            customerPhone: '${subscription['customer_phone'] ?? ''}'.trim(),
            meal: meal,
            menuItemId: rawMenuItemId,
          ),
        );
        menuItemIds.add(rawMenuItemId);
      }
    }

    if (plannedRows.isEmpty || menuItemIds.isEmpty) {
      return SubscriptionOrderGenerationResult(
        insertedCount: 0,
        skippedExistingCount: 0,
        skippedMissingMenuItemCount: 0,
        consideredSubscriptionCount: subscriptions.length,
        targetDate: targetDate,
      );
    }

    final menuItemsResponse = await client
        .from('menu_items')
        .select('id, name, price')
        .inFilter('id', menuItemIds.toList());
    final menuItems = List<Map<String, dynamic>>.from(menuItemsResponse);
    final menuItemById = <String, Map<String, dynamic>>{
      for (final item in menuItems) '${item['id'] ?? ''}': item,
    };

    final existingOrdersResponse = await client
        .from('orders')
        .select('customer_id, meal')
        .eq('order_type', 'subscription')
        .eq('order_date', targetDateKey);
    final existingOrders = List<Map<String, dynamic>>.from(existingOrdersResponse);
    final existingKeys = <String>{
      for (final order in existingOrders)
        _subscriptionOrderKey(
          customerId: '${order['customer_id'] ?? ''}',
          meal: '${order['meal'] ?? ''}',
          orderDate: targetDateKey,
        ),
    };

    final inserts = <Map<String, dynamic>>[];
    var skippedExistingCount = 0;
    var skippedMissingMenuItemCount = 0;

    for (final row in plannedRows) {
      final dedupeKey = _subscriptionOrderKey(
        customerId: row.customerId,
        meal: row.meal,
        orderDate: targetDateKey,
      );

      if (existingKeys.contains(dedupeKey)) {
        skippedExistingCount += 1;
        continue;
      }

      final menuItem = menuItemById[row.menuItemId];
      if (menuItem == null) {
        skippedMissingMenuItemCount += 1;
        continue;
      }

      final price = (menuItem['price'] as num?)?.toDouble() ?? 0;

      inserts.add(<String, dynamic>{
        'customer_id': row.customerId,
        'customer_name': row.customerName,
        'customer_phone': row.customerPhone,
        'customer_address': '',
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'dish_id': row.menuItemId,
            'name': '${menuItem['name'] ?? ''}'.trim(),
            'price': price,
            'quantity': 1,
            'qty': 1,
          },
        ],
        'order_type': 'subscription',
        'meal': row.meal,
        'status': 'placed',
        'picked': false,
        'subtotal': price,
        'delivery_fee': 0,
        'gst': 0,
        'total': price,
        'order_date': targetDateKey,
      });

      existingKeys.add(dedupeKey);
    }

    if (inserts.isNotEmpty) {
      await client.from('orders').insert(inserts);
    }

    return SubscriptionOrderGenerationResult(
      insertedCount: inserts.length,
      skippedExistingCount: skippedExistingCount,
      skippedMissingMenuItemCount: skippedMissingMenuItemCount,
      consideredSubscriptionCount: subscriptions.length,
      targetDate: targetDate,
    );
  }

  static const Set<String> _allowedSubscriptionMeals = <String>{
    'breakfast',
    'lunch',
    'dinner',
    'snacks',
    'beverages',
  };

  List<String> _stringListFromDynamic(dynamic value) {
    if (value is List) {
      return value.map((item) => '$item'.trim()).where((item) => item.isNotEmpty).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded
              .map((item) => '$item'.trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }

    return <String>[];
  }

  Map<String, dynamic> _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, entry) => MapEntry('$key', entry),
      );
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.map(
            (key, entry) => MapEntry('$key', entry),
          );
        }
      } catch (_) {}
    }

    return <String, dynamic>{};
  }

  String _subscriptionOrderKey({
    required String customerId,
    required String meal,
    required String orderDate,
  }) {
    return '${customerId.trim()}|${meal.trim()}|$orderDate';
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _dayKey(DateTime date) {
    const days = <String>['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[date.weekday - 1];
  }
}

class SubscriptionOrderGenerationResult {
  final int insertedCount;
  final int skippedExistingCount;
  final int skippedMissingMenuItemCount;
  final int consideredSubscriptionCount;
  final DateTime targetDate;

  const SubscriptionOrderGenerationResult({
    required this.insertedCount,
    required this.skippedExistingCount,
    required this.skippedMissingMenuItemCount,
    required this.consideredSubscriptionCount,
    required this.targetDate,
  });
}

class _PlannedSubscriptionOrder {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String meal;
  final String menuItemId;

  const _PlannedSubscriptionOrder({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.meal,
    required this.menuItemId,
  });
}
