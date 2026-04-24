import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_snackbar.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/map_placeholder_widget.dart';

class AdminRidersTab extends StatefulWidget {
  const AdminRidersTab({super.key});

  @override
  State<AdminRidersTab> createState() => _AdminRidersTabState();
}

class _AdminRidersTabState extends State<AdminRidersTab> {
  List<Map<String, dynamic>> _riders = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _showMap = false;
  Timer? _mapRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRiders();
    _subscribeToRiders();
  }

  @override
  void dispose() {
    _mapRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRiders() async {
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.instance.client
          .from('users')
          .select()
          .eq('role', 'rider')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _riders = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _subscribeToRiders() {
    SupabaseService.instance.client
        .channel('admin_riders_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (_) => _loadRiders(),
        )
        .subscribe();
  }

  void _showAddRiderSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRiderSheet(
        onSave: (name, email, phone) async {
          Navigator.pop(context);
          await _addRider(name, email, phone);
        },
      ),
    );
  }

  Future<void> _addRider(String name, String email, String phone) async {
    try {
      await SupabaseService.instance.client.from('users').insert({
        'name': name,
        'email': email.trim().toLowerCase(),
        'phone': phone,
        'role': 'rider',
        'status': 'active',
      });
      await _loadRiders();
      if (!mounted) return;

      showSuccessSnackbar(
        context,
        'Rider registered! Ask them to log in with $email. '
        'They must set password via "Forgot Password" on first login.',
      );
    } catch (_) {
      if (mounted) {
        showErrorSnackbar(context, 'Could not add rider');
      }
    }
  }

  Future<void> _toggleRiderStatus(String riderId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    try {
      await SupabaseService.instance.client
          .from('users')
          .update({'status': newStatus})
          .eq('id', riderId);
      await _loadRiders();
    } catch (_) {
      // silent
    }
  }

  Future<void> _showRiderAssignments(Map<String, dynamic> rider) async {
    final riderId = rider['id'] as String;

    try {
      final activeOrdersRes = await SupabaseService.instance.client
          .from('orders')
          .select()
          .eq('rider_id', riderId)
          .inFilter('status', ['out_for_delivery', 'confirmed', 'preparing'])
          .order('created_at', ascending: false);
      final activeOrders = List<Map<String, dynamic>>.from(activeOrdersRes);

      List<Map<String, dynamic>> availableOrders = <Map<String, dynamic>>[];
      if (activeOrders.isEmpty) {
        final availableOrdersRes = await SupabaseService.instance.client
            .from('orders')
            .select('id, customer_name, total, meal, items, order_date, picked')
            .eq('picked', false)
            .order('order_date')
            .order('created_at', ascending: false);
        availableOrders = List<Map<String, dynamic>>.from(availableOrdersRes);
      }

      if (!mounted) return;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RiderAssignmentsSheet(
          rider: rider,
          orders: activeOrders,
          availableOrders: availableOrders,
          onAssign: (orderIds) async {
            Navigator.pop(context);
            await _assignOrdersToRider(orderIds, rider);
          },
        ),
      );
    } catch (_) {
      if (mounted) {
        showErrorSnackbar(context, 'Could not load rider orders');
      }
    }
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

      await _loadRiders();
      if (!mounted) return;

      showSuccessSnackbar(
        context,
        '${orderIds.length} order${orderIds.length == 1 ? '' : 's'} assigned to ${rider['name']}',
      );
    } catch (_) {
      if (mounted) {
        showErrorSnackbar(context, 'Could not assign orders to ${rider['name']}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Text(
                '${_riders.length} Riders',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showMap = !_showMap),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showMap ? AppTheme.primary : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 14,
                        color: _showMap ? Colors.white : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Live Map',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _showMap ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showAddRiderSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Add Rider',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showMap)
          Container(
            height: 220,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withAlpha(30),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: const MapPlaceholderWidget(height: 220),
          ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : RefreshIndicator(
                  onRefresh: _loadRiders,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _riders.length,
                    itemBuilder: (context, index) => _buildRiderCard(_riders[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> rider) {
    final status = rider['status'] as String? ?? 'inactive';
    final isActive = status == 'active';
    final ordersCount = rider['current_orders_count'] as int? ?? 0;
    final riderId = rider['id'] as String;

    return GestureDetector(
      onTap: () => _showRiderAssignments(rider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: isActive
                ? AppTheme.success.withAlpha(30)
                : AppTheme.textMuted.withAlpha(30),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.successLight : AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delivery_dining_rounded,
                size: 22,
                color: isActive ? AppTheme.success : AppTheme.textMuted,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _toggleRiderStatus(riderId, status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.successLight : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppTheme.success : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$ordersCount orders',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRiderSheet extends StatefulWidget {
  final Future<void> Function(String name, String email, String phone) onSave;

  const _AddRiderSheet({required this.onSave});

  @override
  State<_AddRiderSheet> createState() => _AddRiderSheetState();
}

class _AddRiderSheetState extends State<_AddRiderSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add New Rider',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final name = _nameController.text.trim();
                        final email = _emailController.text.trim();
                        final phone = _phoneController.text.trim();
                        if (name.isEmpty || email.isEmpty || phone.isEmpty) {
                          return;
                        }
                        setState(() => _saving = true);
                        await widget.onSave(name, email, phone);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Rider',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderAssignmentsSheet extends StatelessWidget {
  final Map<String, dynamic> rider;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> availableOrders;
  final Future<void> Function(List<String> orderIds) onAssign;

  const _RiderAssignmentsSheet({
    required this.rider,
    required this.orders,
    required this.availableOrders,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _RiderAssignmentPickerSheet(
        rider: rider,
        orders: availableOrders,
        onAssign: onAssign,
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    size: 20,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider['name'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${orders.length} active assignment${orders.length > 1 ? 's' : ''}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final orderId = order['id'] as String? ?? '';
                final shortId = orderId.length > 8
                    ? orderId.substring(0, 8).toUpperCase()
                    : orderId.toUpperCase();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '#$shortId',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order['customer_name'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '₹${(order['total'] as num?)?.toInt() ?? 0}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderAssignmentPickerSheet extends StatefulWidget {
  final Map<String, dynamic> rider;
  final List<Map<String, dynamic>> orders;
  final Future<void> Function(List<String> orderIds) onAssign;

  const _RiderAssignmentPickerSheet({
    required this.rider,
    required this.orders,
    required this.onAssign,
  });

  @override
  State<_RiderAssignmentPickerSheet> createState() =>
      _RiderAssignmentPickerSheetState();
}

class _RiderAssignmentPickerSheetState extends State<_RiderAssignmentPickerSheet> {
  final Set<String> _selectedOrderIds = <String>{};
  bool _assigning = false;

  void _toggleOrder(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  String _itemsSummary(dynamic rawItems) {
    final items = rawItems is List ? rawItems : <dynamic>[];
    if (items.isEmpty) return 'No items';

    return items
        .map((item) {
          if (item is! Map) return '';
          final name = '${item['name'] ?? ''}'.trim();
          final quantity =
              ((item['quantity'] as num?) ?? (item['qty'] as num?) ?? 1).toInt();
          return '$name x$quantity';
        })
        .where((item) => item.isNotEmpty)
        .join(', ');
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign Orders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.rider['name'] as String? ?? ''} has no active assignments',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_selectedOrderIds.length} selected',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.orders.isEmpty
                ? Center(
                    child: Text(
                      'No unpicked orders available.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.orders.length,
                    itemBuilder: (context, index) {
                      final order = widget.orders[index];
                      final orderId = '${order['id'] ?? ''}';
                      final selected = _selectedOrderIds.contains(orderId);
                      final total = (order['total'] as num?)?.toDouble() ?? 0;
                      final meal = '${order['meal'] ?? 'meal'}';

                      return GestureDetector(
                        onTap: () => _toggleOrder(orderId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primaryContainer : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.cardShadow,
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.primary.withAlpha(16),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${order['customer_name'] ?? 'Customer'}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: selected ? AppTheme.primary : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? AppTheme.primary
                                            : AppTheme.textMuted.withAlpha(90),
                                      ),
                                    ),
                                    child: Icon(
                                      selected ? Icons.check_rounded : Icons.add_rounded,
                                      size: 14,
                                      color: selected ? Colors.white : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _itemsSummary(order['items']),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _PickerChip(label: _mealLabel(meal)),
                                  _PickerChip(label: '₹${total.toInt()}'),
                                ],
                              ),
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
                onPressed: _assigning || _selectedOrderIds.isEmpty
                    ? null
                    : () async {
                        setState(() => _assigning = true);
                        await widget.onAssign(_selectedOrderIds.toList());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.textMuted.withAlpha(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _assigning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Assign Selected Orders',
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

class _PickerChip extends StatelessWidget {
  final String label;

  const _PickerChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
