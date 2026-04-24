import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/map_placeholder_widget.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _selectedOrderIds = <String>{};
  final List<RealtimeChannel> _channels = <RealtimeChannel>[];

  List<Map<String, dynamic>> _oneTimeOrders = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _subscriptions = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _tomorrowOrders = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _riders = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _runningTomorrowGeneration = false;

  static const List<String> _statusOptions = <String>[
    'placed',
    'confirmed',
    'preparing',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    for (final channel in _channels) {
      channel.unsubscribe();
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final client = SupabaseService.instance.client;
      final now = DateTime.now();
      final targetDate = _operationalTomorrowDate(now);
      final targetDateKey = _dateKey(targetDate);

      final results = await Future.wait<dynamic>([
        client
            .from('orders')
            .select()
            .order('order_date', ascending: false)
            .order('created_at', ascending: false)
            .limit(300),
        client
            .from('subscriptions')
            .select()
            .inFilter('status', <String>['active', 'paused'])
            .order('created_at', ascending: false),
        client
            .from('users')
            .select()
            .eq('role', 'rider')
            .eq('status', 'active')
            .order('name'),
      ]);

      final allOrders = List<Map<String, dynamic>>.from(results[0] as List);
      final oneTimeOrders = allOrders
          .where((order) => (order['order_type'] as String? ?? 'one_time') != 'subscription')
          .toList();
      final tomorrowOrders = allOrders
          .where(
            (order) =>
                (order['order_type'] as String? ?? '') == 'subscription' &&
                (order['order_date'] as String? ?? '') == targetDateKey,
          )
          .toList();

      final assignableIds = <String>{
        ...oneTimeOrders.where(_isAssignableOrder).map(_orderIdOf),
        ...tomorrowOrders.where(_isAssignableOrder).map(_orderIdOf),
      };

      if (!mounted) return;

      setState(() {
        _oneTimeOrders = oneTimeOrders;
        _subscriptions = List<Map<String, dynamic>>.from(results[1] as List);
        _tomorrowOrders = tomorrowOrders;
        _riders = List<Map<String, dynamic>>.from(results[2] as List);
        _selectedOrderIds.removeWhere((id) => !assignableIds.contains(id));
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _subscribeToRealtime() {
    final client = SupabaseService.instance.client;

    _channels.add(
      client
          .channel('admin_orders_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            callback: (_) => _loadData(),
          )
          .subscribe(),
    );

    _channels.add(
      client
          .channel('admin_subscriptions_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'subscriptions',
            callback: (_) => _loadData(),
          )
          .subscribe(),
    );

    _channels.add(
      client
          .channel('admin_riders_realtime_orders_tab')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'users',
            callback: (_) => _loadData(),
          )
          .subscribe(),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await SupabaseService.instance.client
          .from('orders')
          .update(<String, dynamic>{'status': newStatus})
          .eq('id', orderId);
      await _loadData();
    } catch (_) {}
  }

  Future<void> _assignOrdersToRider(
    List<String> orderIds,
    Map<String, dynamic> rider,
  ) async {
    if (orderIds.isEmpty) return;
    try {
      await SupabaseService.instance.client
          .from('orders')
          .update(<String, dynamic>{
            'status': 'out_for_delivery',
            'picked': true,
            'rider_id': rider['id'],
            'rider_name': rider['name'],
            'rider_phone': rider['phone'],
          })
          .inFilter('id', orderIds);

      if (!mounted) return;

      setState(() => _selectedOrderIds.removeAll(orderIds));
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${orderIds.length} order${orderIds.length == 1 ? '' : 's'} assigned to ${rider['name']}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (_) {}
  }

  Future<void> _runTomorrowOrderGeneration() async {
    if (_runningTomorrowGeneration) return;

    setState(() => _runningTomorrowGeneration = true);

    try {
      final result =
          await SupabaseService.instance.generateTomorrowSubscriptionOrders(
        referenceTime: DateTime.now(),
      );

      if (!mounted) return;
      await _loadData();
      if (!mounted) return;

      final targetDate = result.targetDate;
      final insertedCount = result.insertedCount;
      final existingCount = result.skippedExistingCount;
      final missingMenuItemCount = result.skippedMissingMenuItemCount;
      final targetDateLabel = _formatPrettyDate(targetDate);
      final messageParts = <String>[
        '$insertedCount tomorrow order${insertedCount == 1 ? '' : 's'} created for $targetDateLabel.',
      ];

      if (existingCount > 0) {
        messageParts.add(
          '$existingCount already existed and were skipped.',
        );
      }

      if (missingMenuItemCount > 0) {
        messageParts.add(
          '$missingMenuItemCount were skipped because menu items were missing.',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            messageParts.join(' '),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _buildTomorrowOrderGenerationErrorMessage(error),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _runningTomorrowGeneration = false);
      }
    }
  }

  String _buildTomorrowOrderGenerationErrorMessage(Object error) {
    if (error is PostgrestException) {
      final errorCode = error.code?.trim() ?? '';
      final errorDetails = '${error.details ?? ''}'.trim();
      final errorHint = '${error.hint ?? ''}'.trim();
      final parts = <String>[
        'Tomorrow orders could not be created from subscriptions.',
        'Blocking reason: ${error.message}',
      ];

      if (errorCode.isNotEmpty) {
        parts.add('Error code: $errorCode');
      }

      if (errorDetails.isNotEmpty) {
        parts.add('Details: $errorDetails');
      }

      if (errorHint.isNotEmpty) {
        parts.add('Hint: $errorHint');
      }

      return parts.join('\n');
    }

    return 'Tomorrow orders were not generated.\n'
        'Blocking reason: ${error.runtimeType}: $error';
  }

  void _showAssignRiderSheet(List<String> orderIds) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignRiderSheet(
        riders: _riders,
        selectedOrderCount: orderIds.length,
        onAssign: (rider) {
          Navigator.pop(context);
          _assignOrdersToRider(orderIds, rider);
        },
      ),
    );
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'placed':
        return 'Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'placed':
        return const Color(0xFF2563EB);
      case 'confirmed':
        return const Color(0xFF7C3AED);
      case 'preparing':
        return AppTheme.accent;
      case 'out_for_delivery':
        return AppTheme.primary;
      case 'delivered':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textMuted;
    }
  }

  bool _isAssignableOrder(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'placed';
    return status != 'delivered' && status != 'cancelled';
  }

  bool _isPendingOrder(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'placed';
    return status != 'delivered' && status != 'cancelled';
  }

  String _orderIdOf(Map<String, dynamic> order) {
    return order['id'] as String? ?? '';
  }

  DateTime _operationalTomorrowDate(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (now.hour >= 6) {
      return today;
    }
    return today.add(const Duration(days: 1));
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _parseDateValue(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _formatPrettyDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _mealLabel(String meal) {
    switch (meal) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snacks':
        return 'Snacks';
      case 'beverages':
        return 'Beverages';
      default:
        return meal;
    }
  }

  String _mealEmoji(String meal) {
    switch (meal) {
      case 'breakfast':
        return 'Sunrise';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snacks':
        return 'Snacks';
      case 'beverages':
        return 'Drinks';
      default:
        return 'Meal';
    }
  }

  String _timeAgo(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  String _itemsSummary(List<dynamic> items) {
    if (items.isEmpty) return 'No items';
    return items
        .map((item) {
          if (item is! Map) return '';
          final name = '${item['name'] ?? ''}'.trim();
          final quantity = ((item['quantity'] as num?) ?? (item['qty'] as num?) ?? 1).toInt();
          return '$name x$quantity';
        })
        .where((item) => item.isNotEmpty)
        .join(', ');
  }

  String _subscriptionDishName(Map<String, dynamic> sub, DateTime targetDate) {
    final weeklyPlan = Map<String, dynamic>.from(
      sub['weekly_plan'] as Map? ?? <String, dynamic>{},
    );
    final dayPlan = Map<String, dynamic>.from(
      weeklyPlan[_dayKey(targetDate)] as Map? ?? <String, dynamic>{},
    );
    final meals = (sub['meals'] as List?)?.cast<String>() ?? <String>[];
    return meals
        .map((meal) => '${_mealLabel(meal)}: ${dayPlan[meal] ?? 'Not assigned'}')
        .join('  |  ');
  }

  String _dayKey(DateTime date) {
    const days = <String>['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[date.weekday - 1];
  }

  bool _isBreakfastReady(Map<String, dynamic> order, DateTime now, DateTime targetDate) {
    final orderDate = _parseDateValue(order['order_date'] as String?);
    final today = DateTime(now.year, now.month, now.day);
    return (order['order_type'] as String? ?? '') == 'subscription' &&
        (order['meal'] as String? ?? '') == 'breakfast' &&
        orderDate != null &&
        _dateKey(orderDate) == _dateKey(today) &&
        _dateKey(targetDate) == _dateKey(today) &&
        now.hour >= 6 &&
        _isPendingOrder(order);
  }

  Map<String, Map<String, int>> _buildTomorrowCookSummary(List<Map<String, dynamic>> orders) {
    final summary = <String, Map<String, int>>{};
    for (final order in orders.where(_isPendingOrder)) {
      final meal = order['meal'] as String? ?? 'lunch';
      summary.putIfAbsent(meal, () => <String, int>{});
      final items = List<dynamic>.from(order['items'] as List? ?? <dynamic>[]);
      for (final rawItem in items) {
        if (rawItem is! Map) continue;
        final name = '${rawItem['name'] ?? 'Unnamed item'}'.trim();
        final quantity = ((rawItem['quantity'] as num?) ?? (rawItem['qty'] as num?) ?? 1).toInt();
        summary[meal]![name] = (summary[meal]![name] ?? 0) + quantity;
      }
    }
    return summary;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2.5,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const <Tab>[
                  Tab(text: 'Tomorrow Orders'),
                  Tab(text: 'Subscriptions'),
                  Tab(text: 'OTO'),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        _buildTomorrowOrders(),
                        _buildSubscriptions(),
                        _buildOneTimeOrders(),
                      ],
                    ),
            ),
          ],
        ),
        if (_selectedOrderIds.isNotEmpty) _buildBulkAssignBar(),
      ],
    );
  }

  Widget _buildBulkAssignBar() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.textPrimary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${_selectedOrderIds.length} selected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Assign mixed OTO and subscription orders together.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white.withAlpha(190),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => _selectedOrderIds.clear()),
                child: Text(
                  'Clear',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showAssignRiderSheet(_selectedOrderIds.toList()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Assign Rider',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOneTimeOrders() {
    if (_oneTimeOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No OTO orders yet',
        subtitle: 'New OTO customer orders will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        physics: const BouncingScrollPhysics(),
        itemCount: _oneTimeOrders.length,
        itemBuilder: (context, index) => _buildOneTimeOrderCard(_oneTimeOrders[index]),
      ),
    );
  }

  Widget _buildOneTimeOrderCard(Map<String, dynamic> order) {
    final orderId = _orderIdOf(order);
    final status = order['status'] as String? ?? 'placed';
    final statusColor = _statusColor(status);
    final items = List<dynamic>.from(order['items'] as List? ?? <dynamic>[]);
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final customerName = order['customer_name'] as String? ?? 'Customer';
    final timeAgo = _timeAgo(order['created_at'] as String? ?? '');
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    final selected = _selectedOrderIds.contains(orderId);
    final assignable = _isAssignableOrder(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: selected ? AppTheme.primary : statusColor.withAlpha(28),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$shortId',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                const Spacer(),
                if (assignable)
                  InkWell(
                    onTap: () => _toggleOrderSelection(orderId),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary : Colors.white,
                        border: Border.all(
                          color: selected ? AppTheme.primary : AppTheme.textMuted.withAlpha(90),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        selected ? Icons.check_rounded : Icons.add_rounded,
                        size: 16,
                        color: selected ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatStatus(status),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customerName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Rs ${total.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _itemsSummary(items),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatusDropdown(
                    currentStatus: status,
                    options: _statusOptions,
                    formatStatus: _formatStatus,
                    statusColor: _statusColor,
                    onChanged: (newStatus) {
                      if (newStatus == 'out_for_delivery') {
                        _showAssignRiderSheet(<String>[orderId]);
                      } else {
                        _updateOrderStatus(orderId, newStatus);
                      }
                    },
                  ),
                ),
                if (order['rider_name'] != null) ...<Widget>[
                  const SizedBox(width: 8),
                  _RiderPill(name: order['rider_name'] as String),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptions() {
    if (_subscriptions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.repeat_rounded,
        title: 'No active subscriptions',
        subtitle: 'Active and paused subscriptions will appear here.',
      );
    }

    final targetDate = _operationalTomorrowDate(DateTime.now());

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        physics: const BouncingScrollPhysics(),
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final sub = _subscriptions[index];
          final status = sub['status'] as String? ?? 'active';
          final statusColor = status == 'paused'
              ? AppTheme.warning
              : status == 'cancelled'
                  ? AppTheme.error
                  : AppTheme.success;
          final startDate = _parseDateValue(sub['start_date'] as String?);
          final endDate = _parseDateValue(sub['end_date'] as String?);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: statusColor.withAlpha(25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        sub['customer_name'] as String? ?? 'Customer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _subscriptionDishName(sub, targetDate),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.primary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${startDate != null ? _formatPrettyDate(startDate) : '-'} to ${endDate != null ? _formatPrettyDate(endDate) : '-'}',
                    ),
                    _InfoChip(
                      icon: Icons.restaurant_menu_rounded,
                      label: ((sub['meals'] as List?)?.cast<String>() ?? <String>[])
                          .map(_mealLabel)
                          .join(', '),
                    ),
                    _InfoChip(
                      icon: Icons.schedule_rounded,
                      label: 'Next plan for ${_formatPrettyDate(targetDate)}',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTomorrowOrders() {
    final now = DateTime.now();
    final targetDate = _operationalTomorrowDate(now);
    final summary = _buildTomorrowCookSummary(_tomorrowOrders);
    final groupedOrders = <String, List<Map<String, dynamic>>>{};

    for (final order in _tomorrowOrders) {
      final meal = order['meal'] as String? ?? 'lunch';
      groupedOrders.putIfAbsent(meal, () => <Map<String, dynamic>>[]).add(order);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.inventory_2_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tomorrow Orders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: _runningTomorrowGeneration
                            ? null
                            : _runTomorrowOrderGeneration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          disabledBackgroundColor:
                              AppTheme.textMuted.withAlpha(60),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _runningTomorrowGeneration
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Get Tomorrow Orders',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatPrettyDate(targetDate),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  now.hour >= 6
                      ? 'Breakfast subscriptions for today are ready to be picked up.'
                      : 'Use the button above to generate tomorrow subscription orders.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_tomorrowOrders.isEmpty)
            _buildEmptyState(
              icon: Icons.local_dining_outlined,
              title: 'No subscription orders scheduled',
              subtitle:
                  'Use Get Tomorrow Orders and active subscriptions will appear here.',
            )
          else ...<Widget>[
            if (summary.isNotEmpty) ...<Widget>[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'What To Cook Tomorrow',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prep quantities below are calculated from the orders table `items` data.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ...summary.entries.map((entry) => _buildTomorrowSummaryCard(entry.key, entry.value, groupedOrders[entry.key]?.length ?? 0)),
            const SizedBox(height: 8),
            ...groupedOrders.entries.map((entry) => _buildTomorrowMealOrders(entry.key, entry.value, now, targetDate)),
          ],
        ],
      ),
    );
  }

  Widget _buildTomorrowSummaryCard(String meal, Map<String, int> items, int orderCount) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.primary.withAlpha(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _mealLabel(meal),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$orderCount order${orderCount == 1 ? '' : 's'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.entries.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.key,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.value}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTomorrowMealOrders(
    String meal,
    List<Map<String, dynamic>> orders,
    DateTime now,
    DateTime targetDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            '${_mealEmoji(meal)} ${_mealLabel(meal)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        ...orders.map((order) => _buildTomorrowOrderCard(order, now, targetDate)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTomorrowOrderCard(
    Map<String, dynamic> order,
    DateTime now,
    DateTime targetDate,
  ) {
    final orderId = _orderIdOf(order);
    final selected = _selectedOrderIds.contains(orderId);
    final assignable = _isAssignableOrder(order);
    final status = order['status'] as String? ?? 'placed';
    final statusColor = _statusColor(status);
    final items = List<dynamic>.from(order['items'] as List? ?? <dynamic>[]);
    final ready = _isBreakfastReady(order, now, targetDate);
    final riderName = order['rider_name'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.primary.withAlpha(18),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  order['customer_name'] as String? ?? 'Customer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (assignable)
                InkWell(
                  onTap: () => _toggleOrderSelection(orderId),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Colors.white,
                      border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.textMuted.withAlpha(90),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.add_rounded,
                      size: 16,
                      color: selected ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _itemsSummary(items),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatStatus(status),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              if (ready)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ready to be picked up',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              if (riderName != null) _RiderPill(name: riderName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String currentStatus;
  final List<String> options;
  final String Function(String) formatStatus;
  final Color Function(String) statusColor;
  final ValueChanged<String> onChanged;

  const _StatusDropdown({
    required this.currentStatus,
    required this.options,
    required this.formatStatus,
    required this.statusColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor(currentStatus).withAlpha(40),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppTheme.textMuted,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: statusColor(currentStatus),
          ),
          items: options.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                formatStatus(status),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor(status),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null && value != currentStatus) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _AssignRiderSheet extends StatefulWidget {
  final List<Map<String, dynamic>> riders;
  final int selectedOrderCount;
  final ValueChanged<Map<String, dynamic>> onAssign;

  const _AssignRiderSheet({
    required this.riders,
    required this.selectedOrderCount,
    required this.onAssign,
  });

  @override
  State<_AssignRiderSheet> createState() => _AssignRiderSheetState();
}

class _AssignRiderSheetState extends State<_AssignRiderSheet> {
  String? _selectedRiderId;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Assign Rider',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.selectedOrderCount} order${widget.selectedOrderCount == 1 ? '' : 's'} selected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.riders.length} available',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withAlpha(30),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: const MapPlaceholderWidget(height: 160),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: widget.riders.isEmpty
                ? Center(
                    child: Text(
                      'No active riders available',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.riders.length,
                    itemBuilder: (context, index) {
                      final rider = widget.riders[index];
                      final riderId = rider['id'] as String;
                      final selected = _selectedRiderId == riderId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRiderId = riderId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primaryContainer : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.primary.withAlpha(20),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.primary : AppTheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delivery_dining_rounded,
                                  size: 20,
                                  color: selected ? Colors.white : AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      rider['name'] as String? ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      rider['phone'] as String? ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.successLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${rider['current_orders_count'] ?? 0} orders',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ),
                              if (selected) ...<Widget>[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedRiderId == null
                    ? null
                    : () {
                        final rider = widget.riders.firstWhere(
                          (row) => row['id'] == _selectedRiderId,
                        );
                        widget.onAssign(rider);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.textMuted.withAlpha(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Assign Rider',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderPill extends StatelessWidget {
  final String name;

  const _RiderPill({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.delivery_dining_rounded,
            size: 12,
            color: AppTheme.success,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
