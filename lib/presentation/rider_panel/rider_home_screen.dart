import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class RiderHomeScreen extends StatefulWidget {
  final String riderName;
  final String riderId;
  final String riderPhone;

  const RiderHomeScreen({
    super.key,
    required this.riderName,
    required this.riderId,
    required this.riderPhone,
  });

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  static const List<String> _activeStatuses = <String>[
    'placed',
    'confirmed',
    'preparing',
    'out_for_delivery',
  ];

  final Set<String> _ignoredOrderIds = <String>{};
  final Set<String> _busyOrderIds = <String>{};

  List<Map<String, dynamic>> _availableOrders = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _activeOrders = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _completedOrders = <Map<String, dynamic>>[];
  bool _loading = true;
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _subscribeToOrders();
  }

  @override
  void didUpdateWidget(covariant RiderHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riderId != widget.riderId) {
      _ordersChannel?.unsubscribe();
      _subscribeToOrders();
      _loadOrders();
    }
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (widget.riderId.isEmpty) {
      if (mounted) {
        setState(() {
          _availableOrders = <Map<String, dynamic>>[];
          _activeOrders = <Map<String, dynamic>>[];
          _completedOrders = <Map<String, dynamic>>[];
          _loading = false;
        });
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final today = DateTime.now();
      final todayStart = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();

      final results = await Future.wait<dynamic>([
        SupabaseService.instance.client
            .from('orders')
            .select()
            .eq('picked', false)
            .eq('status', 'placed')
            .order('created_at', ascending: false),
        SupabaseService.instance.client
            .from('orders')
            .select()
            .eq('rider_id', widget.riderId)
            .eq('picked', true)
            .inFilter('status', _activeStatuses)
            .order('created_at', ascending: false),
        SupabaseService.instance.client
            .from('orders')
            .select()
            .eq('rider_id', widget.riderId)
            .eq('status', 'delivered')
            .gte('updated_at', todayStart)
            .order('updated_at', ascending: false),
      ]);

      final available = List<Map<String, dynamic>>.from(results[0] as List)
          .where((order) => !_ignoredOrderIds.contains(order['id'] as String?))
          .toList();

      if (mounted) {
        setState(() {
          _availableOrders = available;
          _activeOrders = List<Map<String, dynamic>>.from(results[1] as List);
          _completedOrders = List<Map<String, dynamic>>.from(results[2] as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnackBar('Unable to refresh orders right now.', isError: true);
      }
    }
  }

  void _subscribeToOrders() {
    _ordersChannel = SupabaseService.instance.client
        .channel('rider_orders_${widget.riderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => _loadOrders(),
        )
        .subscribe();
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final orderId = order['id'] as String?;
    if (orderId == null || _busyOrderIds.contains(orderId)) return;

    setState(() => _busyOrderIds.add(orderId));

    try {
      final nextStatus = (order['status'] as String?) == 'placed'
          ? 'confirmed'
          : (order['status'] as String? ?? 'confirmed');

      final claimed = await SupabaseService.instance.client
          .from('orders')
          .update({
            'picked': true,
            'rider_id': widget.riderId,
            'rider_name': widget.riderName,
            'rider_phone': widget.riderPhone,
            'status': nextStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('picked', false)
          .select('id')
          .maybeSingle();

      if (!mounted) return;

      if (claimed == null) {
        _showSnackBar('This order was already taken by another rider.');
      } else {
        HapticFeedback.mediumImpact();
        _ignoredOrderIds.remove(orderId);
        _showSnackBar('Order accepted and moved to active deliveries.');
        await _loadOrders();
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Unable to accept this order.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyOrderIds.remove(orderId));
      }
    }
  }

  void _ignoreOrder(String orderId) {
    HapticFeedback.selectionClick();
    setState(() {
      _ignoredOrderIds.add(orderId);
      _availableOrders = _availableOrders
          .where((order) => order['id'] != orderId)
          .toList();
    });
    _showSnackBar('Order ignored for now.');
  }

  Future<void> _markDelivered(String orderId) async {
    if (_busyOrderIds.contains(orderId)) return;
    setState(() => _busyOrderIds.add(orderId));

    try {
      await SupabaseService.instance.client
          .from('orders')
          .update({
            'status': 'delivered',
            'delivered_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      _showSnackBar('Order marked as delivered.');
      await _loadOrders();
    } catch (_) {
      if (mounted) {
        _showSnackBar('Unable to update delivery status.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyOrderIds.remove(orderId));
      }
    }
  }

  Future<void> _openGoogleMaps(
    String address,
    double? lat,
    double? lng,
  ) async {
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
      if (!await launchUrl(uri)) {
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final encoded = Uri.encodeComponent(address);
    uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatItems(dynamic items) {
    if (items == null) return 'No items';
    try {
      final list = items as List;
      if (list.isEmpty) return 'No items';
      return list
              .take(2)
              .map((item) => '${item['name']} x${item['quantity'] ?? 1}')
              .join(', ') +
          (list.length > 2 ? ' +${list.length - 2} more' : '');
    } catch (_) {
      return 'Items';
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  String _formatAmount(num? total) {
    final value = total?.toDouble() ?? 0;
    return 'Rs ${value.toStringAsFixed(0)}';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'placed':
        return 'Placed';
      case 'confirmed':
        return 'Accepted';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else ...[
              _buildSectionHeader('Available Orders', _availableOrders.length),
              if (_availableOrders.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(
                  title: 'No new orders',
                  subtitle: 'Orders waiting to be picked will appear here.',
                  icon: Icons.inbox_rounded,
                  borderColor: const Color(0xFFE5E7EB),
                ))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildAvailableCard(_availableOrders[index]),
                    childCount: _availableOrders.length,
                  ),
                ),
              _buildSectionHeader('Active Deliveries', _activeOrders.length),
              if (_activeOrders.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(
                  title: 'No active deliveries',
                  subtitle: 'Accepted orders move here until they are delivered.',
                  icon: Icons.delivery_dining_rounded,
                  borderColor: const Color(0xFFBAE6FD),
                ))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildActiveCard(_activeOrders[index]),
                    childCount: _activeOrders.length,
                  ),
                ),
              _buildSectionHeader('Completed Today', _completedOrders.length),
              if (_completedOrders.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(
                  title: 'No completed deliveries yet',
                  subtitle: 'Delivered orders from today will appear here.',
                  icon: Icons.check_circle_rounded,
                  borderColor: const Color(0xFFD1FAE5),
                ))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildCompletedCard(_completedOrders[index]),
                    childCount: _completedOrders.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 90,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A7C59), Color(0xFF2D5A3D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/menaka_logo.svg',
                          fit: BoxFit.contain,
                          semanticsLabel: 'Menaka Home Foods logo',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menaka',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Hello, ${widget.riderName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(220),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildOnlineChip(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_availableOrders.length} available  |  ${_activeOrders.length} active  |  ${_completedOrders.length} completed today',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(56)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Online',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: borderColor.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCard(Map<String, dynamic> order) {
    final orderId = order['id'] as String? ?? '';
    final customerName = order['customer_name'] as String? ?? 'Customer';
    final address = order['customer_address'] as String? ?? 'No address';
    final total = order['total'] as num?;
    final busy = _busyOrderIds.contains(orderId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        customerName.isEmpty
                            ? 'C'
                            : customerName[0].toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _formatAmount(total),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order['status'] as String? ?? 'placed'),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoLine(Icons.restaurant_rounded, _formatItems(order['items'])),
              const SizedBox(height: 6),
              _buildInfoLine(Icons.location_on_rounded, address),
              const SizedBox(height: 6),
              _buildInfoLine(
                Icons.schedule_rounded,
                'Placed at ${_formatTime(order['created_at'] as String?)}',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _ignoreOrder(orderId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Ignore',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy ? null : () => _acceptOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Accept',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCard(Map<String, dynamic> order) {
    final orderId = order['id'] as String? ?? '';
    final address = order['customer_address'] as String? ?? 'No address';
    final customerName = order['customer_name'] as String? ?? 'Customer';
    final customerLat = (order['customer_lat'] as num?)?.toDouble();
    final customerLng = (order['customer_lng'] as num?)?.toDouble();
    final busy = _busyOrderIds.contains(orderId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withAlpha(18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        customerName.isEmpty
                            ? 'C'
                            : customerName[0].toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _formatAmount(order['total'] as num?),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0EA5E9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order['status'] as String? ?? 'confirmed'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildInfoLine(Icons.location_on_rounded, address),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildInfoLine(
                Icons.restaurant_rounded,
                _formatItems(order['items']),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => _openGoogleMaps(address, customerLat, customerLng),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFF7DD3FC)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.map_rounded,
                          size: 28,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Open route in Maps',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openGoogleMaps(address, customerLat, customerLng),
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: Text(
                        'Navigate',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : () => _showDeliveredConfirm(orderId),
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 16),
                      label: Text(
                        'Delivered',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    late final Color background;
    late final Color foreground;

    switch (status) {
      case 'placed':
        background = const Color(0xFFFDE68A);
        foreground = const Color(0xFF92400E);
        break;
      case 'confirmed':
        background = const Color(0xFFD1FAE5);
        foreground = const Color(0xFF065F46);
        break;
      case 'preparing':
        background = const Color(0xFFFEF3C7);
        foreground = const Color(0xFFB45309);
        break;
      case 'out_for_delivery':
        background = const Color(0xFFDBEAFE);
        foreground = const Color(0xFF1D4ED8);
        break;
      default:
        background = const Color(0xFFF3F4F6);
        foreground = const Color(0xFF374151);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatStatus(status),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedCard(Map<String, dynamic> order) {
    final customerName = order['customer_name'] as String? ?? 'Customer';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1FAE5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatItems(order['items']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(order['total'] as num?),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
                Text(
                  _formatTime(order['updated_at'] as String?),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliveredConfirm(String orderId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mark as delivered?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Confirm that this delivery has been completed.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _markDelivered(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
