import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';

class AdminAnalyticsTab extends StatefulWidget {
  const AdminAnalyticsTab({super.key});

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab> {
  bool _loading = true;
  int _todayOrders = 0;
  double _todayRevenue = 0;
  int _activeSubscriptions = 0;
  int _activeRiders = 0;
  List<_DayData> _last7Days = <_DayData>[];
  List<Map<String, dynamic>> _riderRows = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      final client = SupabaseService.instance.client;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      final todayOrdersRes = await client
          .from('orders')
          .select('total, status')
          .gte('created_at', todayStart);
      final todayOrders = List<Map<String, dynamic>>.from(todayOrdersRes);
      final todayRevenue = todayOrders.fold<double>(
        0,
        (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0),
      );

      final subsRes = await client
          .from('subscriptions')
          .select('id')
          .eq('status', 'active');
      final activeSubs = subsRes.length;

      final ridersRes = await client
          .from('users')
          .select('id, name, phone, current_orders_count, status')
          .eq('role', 'rider')
          .eq('status', 'active')
          .order('name');
      final riderRows = List<Map<String, dynamic>>.from(ridersRes);
      final activeRiders = riderRows.length;

      final sevenDaysAgo = now.subtract(const Duration(days: 6));
      final sevenDaysStart =
          DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day)
              .toIso8601String();
      final weekOrdersRes = await client
          .from('orders')
          .select('created_at, total')
          .gte('created_at', sevenDaysStart)
          .order('created_at');
      final weekOrders = List<Map<String, dynamic>>.from(weekOrdersRes);

      final Map<String, _DayData> dayMap = <String, _DayData>{};
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: 6 - i));
        final key =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        dayMap[key] = _DayData(
          label: _shortDay(day.weekday),
          count: 0,
          revenue: 0,
        );
      }

      for (final order in weekOrders) {
        final createdAt = order['created_at'] as String? ?? '';
        if (createdAt.isEmpty) continue;

        final dt = DateTime.tryParse(createdAt)?.toLocal();
        if (dt == null) continue;

        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        if (!dayMap.containsKey(key)) continue;

        dayMap[key] = _DayData(
          label: dayMap[key]!.label,
          count: dayMap[key]!.count + 1,
          revenue:
              dayMap[key]!.revenue +
              ((order['total'] as num?)?.toDouble() ?? 0),
        );
      }

      if (!mounted) return;

      setState(() {
        _todayOrders = todayOrders.length;
        _todayRevenue = todayRevenue;
        _activeSubscriptions = activeSubs;
        _activeRiders = activeRiders;
        _last7Days = dayMap.values.toList();
        _riderRows = riderRows;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _shortDay(int weekday) {
    const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Future<void> _showRiderAssignmentSheet(Map<String, dynamic> rider) async {
    try {
      final orders = await SupabaseService.instance.client
          .from('orders')
          .select(
            'id, customer_name, total, meal, items, order_type, order_date, picked',
          )
          .eq('picked', false)
          .order('order_date')
          .order('created_at', ascending: false);

      if (!mounted) return;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AnalyticsRiderAssignmentSheet(
          rider: rider,
          orders: List<Map<String, dynamic>>.from(orders),
          onAssign: (orderIds) async {
            Navigator.of(context).pop();
            await _assignOrdersToRider(orderIds, rider);
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load unpicked orders.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
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

      await _loadAnalytics();
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
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not assign orders to ${rider['name']}.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Overview",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _StatCard(
                  title: "Today's Orders",
                  value: '$_todayOrders',
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.primary,
                  subtitle: 'One-time orders',
                ),
                _StatCard(
                  title: "Today's Revenue",
                  value: '₹${_todayRevenue.toInt()}',
                  icon: Icons.currency_rupee_rounded,
                  color: AppTheme.accent,
                  subtitle: 'Gross earnings',
                ),
                _StatCard(
                  title: 'Active Subs',
                  value: '$_activeSubscriptions',
                  icon: Icons.repeat_rounded,
                  color: const Color(0xFF7C3AED),
                  subtitle: 'Subscriptions',
                ),
                _StatCard(
                  title: 'Active Riders',
                  value: '$_activeRiders',
                  icon: Icons.delivery_dining_rounded,
                  color: const Color(0xFF2563EB),
                  subtitle: 'On duty',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Riders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a rider to assign orders where picked is false.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            if (_riderRows.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Text(
                  'No active riders available for assignment.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            else
              Column(
                children: _riderRows
                    .map(
                      (rider) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AnalyticsRiderCard(
                          rider: rider,
                          onTap: () => _showRiderAssignmentSheet(rider),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            Text(
              'Last 7 Days - Orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Daily order count for the past week',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: _last7Days.isEmpty
                  ? Center(
                      child: Text(
                        'No data available',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (_last7Days
                                    .map((day) => day.count)
                                    .reduce((a, b) => a > b ? a : b)
                                    .toDouble() +
                                2)
                            .clamp(5, double.infinity),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: AppTheme.secondary,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${_last7Days[groupIndex].count} orders',
                                GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= _last7Days.length) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _last7Days[index].label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                if (value % 2 != 0) {
                                  return const SizedBox.shrink();
                                }

                                return Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppTheme.surfaceVariant,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          _last7Days.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _last7Days[index].count.toDouble(),
                                color: AppTheme.primary,
                                width: 22,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: (_last7Days
                                              .map((day) => day.count)
                                              .reduce((a, b) => a > b ? a : b)
                                              .toDouble() +
                                          2)
                                      .clamp(5, double.infinity),
                                  color: AppTheme.surfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              'Last 7 Days - Revenue',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: List.generate(_last7Days.length, (index) {
                  final day = _last7Days[index];
                  final maxRevenue = _last7Days
                      .map((entry) => entry.revenue)
                      .reduce((a, b) => a > b ? a : b);
                  final fraction = maxRevenue > 0 ? day.revenue / maxRevenue : 0.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      index == 0 ? 12 : 8,
                      16,
                      index == _last7Days.length - 1 ? 12 : 0,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            day.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction,
                              backgroundColor: AppTheme.surfaceVariant,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.accent,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '₹${day.revenue.toInt()}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DayData {
  final String label;
  final int count;
  final double revenue;

  const _DayData({
    required this.label,
    required this.count,
    required this.revenue,
  });
}

class _AnalyticsRiderCard extends StatelessWidget {
  final Map<String, dynamic> rider;
  final VoidCallback onTap;

  const _AnalyticsRiderCard({
    required this.rider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ordersCount = (rider['current_orders_count'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: AppTheme.primary.withAlpha(18)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                size: 22,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rider['name'] ?? ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rider['phone'] ?? ''}',
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
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$ordersCount orders',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRiderAssignmentSheet extends StatefulWidget {
  final Map<String, dynamic> rider;
  final List<Map<String, dynamic>> orders;
  final Future<void> Function(List<String> orderIds) onAssign;

  const _AnalyticsRiderAssignmentSheet({
    required this.rider,
    required this.orders,
    required this.onAssign,
  });

  @override
  State<_AnalyticsRiderAssignmentSheet> createState() =>
      _AnalyticsRiderAssignmentSheetState();
}

class _AnalyticsRiderAssignmentSheetState
    extends State<_AnalyticsRiderAssignmentSheet> {
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
                        '${widget.rider['name'] ?? ''} • ${widget.orders.length} unpicked order${widget.orders.length == 1 ? '' : 's'}',
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
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                      final orderDate = _prettyDate('${order['order_date'] ?? ''}');

                      return GestureDetector(
                        onTap: () => _toggleOrder(orderId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primaryContainer
                                : Colors.white,
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
                                      color: selected
                                          ? AppTheme.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? AppTheme.primary
                                            : AppTheme.textMuted.withAlpha(90),
                                      ),
                                    ),
                                    child: Icon(
                                      selected
                                          ? Icons.check_rounded
                                          : Icons.add_rounded,
                                      size: 14,
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.textMuted,
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
                                  _SheetChip(label: _mealLabel(meal)),
                                  if (orderDate.isNotEmpty)
                                    _SheetChip(label: orderDate),
                                  _SheetChip(label: '₹${total.toInt()}'),
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

class _SheetChip extends StatelessWidget {
  final String label;

  const _SheetChip({required this.label});

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

List<dynamic> _itemsFromOrderValue(dynamic value) {
  if (value is List) {
    return value;
  }

  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded;
      }
    } catch (_) {}
  }

  return <dynamic>[];
}

String _itemsSummary(dynamic rawItems) {
  final items = _itemsFromOrderValue(rawItems);
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

String _prettyDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '';

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
  return '${parsed.day} ${months[parsed.month - 1]}';
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withAlpha(30), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
