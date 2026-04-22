import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class RiderProfileScreen extends StatefulWidget {
  final String riderName;
  final String riderPhone;
  final String riderId;
  final VoidCallback onLogout;

  const RiderProfileScreen({
    super.key,
    required this.riderName,
    required this.riderPhone,
    required this.riderId,
    required this.onLogout,
  });

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  bool _loading = true;
  RiderAnalytics _analytics = const RiderAnalytics();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  @override
  void didUpdateWidget(covariant RiderProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riderId != widget.riderId) {
      _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    if (widget.riderId.isEmpty) {
      if (mounted) {
        setState(() {
          _analytics = const RiderAnalytics();
          _loading = false;
        });
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final activeFuture = SupabaseService.instance.client
          .from('orders')
          .select('id')
          .eq('rider_id', widget.riderId)
          .eq('picked', true)
          .inFilter('status', ['placed', 'confirmed', 'preparing', 'out_for_delivery']);

      final deliveredFuture = SupabaseService.instance.client
          .from('orders')
          .select('total,rating,updated_at,delivered_at')
          .eq('rider_id', widget.riderId)
          .eq('status', 'delivered')
          .order('updated_at', ascending: false);

      final results = await Future.wait<dynamic>([activeFuture, deliveredFuture]);
      final activeOrders = List<Map<String, dynamic>>.from(results[0] as List);
      final deliveredOrders = List<Map<String, dynamic>>.from(results[1] as List);

      final revenue = deliveredOrders.fold<double>(
        0,
        (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0),
      );

      final ratings = deliveredOrders
          .map((order) => (order['rating'] as num?)?.toDouble())
          .whereType<double>()
          .toList();

      final averageRating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final completedToday = deliveredOrders.where((order) {
        final value = order['delivered_at'] as String? ?? order['updated_at'] as String?;
        if (value == null) return false;
        final parsed = DateTime.tryParse(value)?.toLocal();
        if (parsed == null) return false;
        return !parsed.isBefore(todayStart);
      }).length;

      final lastDeliveryTime = deliveredOrders.isEmpty
          ? null
          : (deliveredOrders.first['delivered_at'] as String? ??
              deliveredOrders.first['updated_at'] as String?);

      if (mounted) {
        setState(() {
          _analytics = RiderAnalytics(
            completedRides: deliveredOrders.length,
            revenue: revenue,
            averageRating: averageRating,
            ratedDeliveries: ratings.length,
            activeOrders: activeOrders.length,
            completedToday: completedToday,
            lastDeliveryTime: lastDeliveryTime,
          );
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.riderName.isNotEmpty
        ? widget.riderName
              .trim()
              .split(' ')
              .map((word) => word.isNotEmpty ? word[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'R';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withAlpha(60),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.riderName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.electric_bike_rounded,
                    size: 14,
                    color: Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Delivery Rider',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF0EA5E9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.person_rounded,
                      label: 'Full Name',
                      value: widget.riderName,
                    ),
                    const Divider(height: 1, color: Color(0xFFBAE6FD)),
                    _buildInfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Phone Number',
                      value: widget.riderPhone,
                    ),
                    const Divider(height: 1, color: Color(0xFFBAE6FD)),
                    _buildInfoRow(
                      icon: Icons.circle,
                      label: 'Status',
                      value: 'Online',
                      valueColor: const Color(0xFF059669),
                      iconColor: const Color(0xFF4ADE80),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildAnalyticsCard(),
              const SizedBox(height: 24),
              _buildLocationCard(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1FAE5)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Analytics',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: [
              _buildStatTile(
                label: 'Rides Completed',
                value: '${_analytics.completedRides}',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF059669),
              ),
              _buildStatTile(
                label: 'Revenue',
                value: 'Rs ${_analytics.revenue.toStringAsFixed(0)}',
                icon: Icons.currency_rupee_rounded,
                color: const Color(0xFF2563EB),
              ),
              _buildStatTile(
                label: 'Average Rating',
                value: _analytics.ratedDeliveries == 0
                    ? 'No ratings'
                    : '${_analytics.averageRating.toStringAsFixed(1)} / 5',
                icon: Icons.star_rounded,
                color: AppTheme.ratingGold,
              ),
              _buildStatTile(
                label: 'Active Orders',
                value: '${_analytics.activeOrders}',
                icon: Icons.delivery_dining_rounded,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniMetric(
                    'Completed Today',
                    '${_analytics.completedToday}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: _buildMiniMetric(
                    'Last Delivery',
                    _formatLastDelivery(_analytics.lastDeliveryTime),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF1D4ED8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Location Active',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
                Text(
                  'Broadcasting every 5 seconds',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
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
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF0EA5E9)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastDelivery(String? isoString) {
    if (isoString == null) return 'No deliveries';
    final parsed = DateTime.tryParse(isoString)?.toLocal();
    if (parsed == null) return 'No deliveries';
    final hour = parsed.hour > 12
        ? parsed.hour - 12
        : (parsed.hour == 0 ? 12 : parsed.hour);
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    return '${parsed.day}/${parsed.month} $hour:$minute $period';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your live location will stop broadcasting and you will be set to offline.',
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
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class RiderAnalytics {
  final int completedRides;
  final double revenue;
  final double averageRating;
  final int ratedDeliveries;
  final int activeOrders;
  final int completedToday;
  final String? lastDeliveryTime;

  const RiderAnalytics({
    this.completedRides = 0,
    this.revenue = 0,
    this.averageRating = 0,
    this.ratedDeliveries = 0,
    this.activeOrders = 0,
    this.completedToday = 0,
    this.lastDeliveryTime,
  });
}
