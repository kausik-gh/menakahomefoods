import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/map_placeholder_widget.dart';
import '../../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _oneTimeOrders = [];
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _riders = [];
  bool _loading = true;

  final List<String> _statusOptions = [
    'placed',
    'confirmed',
    'preparing',
    'out_for_delivery',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final client = SupabaseService.instance.client;
      final ordersRes = await client
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      final subsRes = await client
          .from('subscriptions')
          .select()
          .inFilter('status', ['active', 'paused'])
          .order('created_at', ascending: false);
      final ridersRes = await client
          .from('users')
          .select()
          .eq('role', 'rider')
          .eq('status', 'active');
      if (mounted) {
        setState(() {
          _oneTimeOrders = List<Map<String, dynamic>>.from(ordersRes);
          _subscriptions = List<Map<String, dynamic>>.from(subsRes);
          _riders = List<Map<String, dynamic>>.from(ridersRes);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeToOrders() {
    SupabaseService.instance.client
        .channel('admin_orders_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => _loadData(),
        )
        .subscribe();
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await SupabaseService.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      await _loadData();
    } catch (e) {
      // silent
    }
  }

  Future<void> _assignRider(String orderId, Map<String, dynamic> rider) async {
    try {
      await SupabaseService.instance.client
          .from('orders')
          .update({
            'status': 'out_for_delivery',
            'picked': true,
            'rider_id': rider['id'],
            'rider_name': rider['name'],
            'rider_phone': rider['phone'],
          })
          .eq('id', orderId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🛵 ${rider['name']} assigned successfully!',
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
      }
    } catch (e) {
      // silent
    }
  }

  void _showAssignRiderSheet(String orderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignRiderSheet(
        riders: _riders,
        onAssign: (rider) {
          Navigator.pop(context);
          _assignRider(orderId, rider);
        },
      ),
    );
  }

  String _formatStatus(String s) {
    switch (s) {
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
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
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
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
            tabs: const [
              Tab(text: 'One-time Orders'),
              Tab(text: 'Subscriptions'),
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
                  children: [_buildOneTimeOrders(), _buildSubscriptions()],
                ),
        ),
      ],
    );
  }

  Widget _buildOneTimeOrders() {
    if (_oneTimeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No orders yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _oneTimeOrders.length,
        itemBuilder: (context, i) => _buildOrderCard(_oneTimeOrders[i]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'placed';
    final statusColor = _statusColor(status);
    final items = order['items'] as List? ?? [];
    final itemsSummary = items
        .take(2)
        .map((it) => '${it['name'] ?? ''} ×${it['quantity'] ?? 1}')
        .join(', ');
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final customerName = order['customer_name'] as String? ?? 'Customer';
    final createdAt = order['created_at'] as String? ?? '';
    final timeAgo = _timeAgo(createdAt);
    final orderId = order['id'] as String? ?? '';
    final shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: statusColor.withAlpha(30), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
              children: [
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
                  '₹${total.toInt()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            if (itemsSummary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                itemsSummary,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusDropdown(
                    currentStatus: status,
                    options: _statusOptions,
                    formatStatus: _formatStatus,
                    statusColor: _statusColor,
                    onChanged: (newStatus) {
                      if (newStatus == 'out_for_delivery') {
                        _showAssignRiderSheet(orderId);
                      } else {
                        _updateOrderStatus(orderId, newStatus);
                      }
                    },
                  ),
                ),
                if (order['rider_name'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.delivery_dining_rounded,
                          size: 12,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order['rider_name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.repeat_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No active subscriptions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final today = DateTime.now();
    final dayKey = _dayKey(today);

    // Group by meal type
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'breakfast': [],
      'lunch': [],
      'dinner': [],
    };

    for (final sub in _subscriptions) {
      final meals = (sub['meals'] as List?)?.cast<String>() ?? [];
      final weeklyPlan = sub['weekly_plan'] as Map<String, dynamic>? ?? {};
      final dayPlan = weeklyPlan[dayKey] as Map<String, dynamic>? ?? {};
      for (final meal in meals) {
        if (grouped.containsKey(meal)) {
          grouped[meal]!.add({
            ...sub,
            '_dish': dayPlan[meal] ?? 'Not assigned',
          });
        }
      }
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMealGroup('🌅 Breakfast', grouped['breakfast']!),
          _buildMealGroup('☀️ Lunch', grouped['lunch']!),
          _buildMealGroup('🌙 Dinner', grouped['dinner']!),
        ],
      ),
    );
  }

  Widget _buildMealGroup(String title, List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        ...entries.map((e) => _buildSubscriptionCard(e)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> sub) {
    final name = sub['customer_name'] as String? ?? 'Customer';
    final address = sub['customer_address'] as String? ?? '';
    final dish = sub['_dish'] as String? ?? 'Not assigned';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.primary.withAlpha(20), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  dish,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (address.isNotEmpty)
                  Text(
                    address,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayKey(DateTime date) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[date.weekday - 1];
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
          items: options.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(
                formatStatus(s),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor(s),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null && val != currentStatus) onChanged(val);
          },
        ),
      ),
    );
  }
}

class _AssignRiderSheet extends StatefulWidget {
  final List<Map<String, dynamic>> riders;
  final ValueChanged<Map<String, dynamic>> onAssign;

  const _AssignRiderSheet({required this.riders, required this.onAssign});

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
        children: [
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
              children: [
                Text(
                  'Assign Rider',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
          // Mini Map
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
                    itemBuilder: (context, i) {
                      final rider = widget.riders[i];
                      final riderId = rider['id'] as String;
                      final isSelected = _selectedRiderId == riderId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRiderId = riderId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryContainer
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.primary.withAlpha(20),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delivery_dining_rounded,
                                  size: 20,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
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
                              if (isSelected) ...[
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
                          (r) => r['id'] == _selectedRiderId,
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
