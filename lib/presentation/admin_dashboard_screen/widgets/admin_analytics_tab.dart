import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';

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
  List<_DayData> _last7Days = [];

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
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();

      // Today's orders
      final todayOrdersRes = await client
          .from('orders')
          .select('total, status')
          .gte('created_at', todayStart);
      final todayOrders = List<Map<String, dynamic>>.from(todayOrdersRes);
      final todayRevenue = todayOrders.fold<double>(
        0,
        (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0),
      );

      // Active subscriptions
      final subsRes = await client
          .from('subscriptions')
          .select('id')
          .eq('status', 'active');
      final activeSubs = subsRes.length;

      // Active riders
      final ridersRes = await client
          .from('riders')
          .select('id')
          .eq('status', 'active');
      final activeRiders = ridersRes.length;

      // Last 7 days orders
      final sevenDaysAgo = now.subtract(const Duration(days: 6));
      final sevenDaysStart = DateTime(
        sevenDaysAgo.year,
        sevenDaysAgo.month,
        sevenDaysAgo.day,
      ).toIso8601String();
      final weekOrdersRes = await client
          .from('orders')
          .select('created_at, total')
          .gte('created_at', sevenDaysStart)
          .order('created_at');
      final weekOrders = List<Map<String, dynamic>>.from(weekOrdersRes);

      // Group by day
      final Map<String, _DayData> dayMap = {};
      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: 6 - i));
        final key =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        dayMap[key] = _DayData(
          label: _shortDay(d.weekday),
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
        if (dayMap.containsKey(key)) {
          dayMap[key] = _DayData(
            label: dayMap[key]!.label,
            count: dayMap[key]!.count + 1,
            revenue:
                dayMap[key]!.revenue +
                ((order['total'] as num?)?.toDouble() ?? 0),
          );
        }
      }

      if (mounted) {
        setState(() {
          _todayOrders = todayOrders.length;
          _todayRevenue = todayRevenue;
          _activeSubscriptions = activeSubs;
          _activeRiders = activeRiders;
          _last7Days = dayMap.values.toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _shortDay(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
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
              childAspectRatio: 1.55,
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
              'Last 7 Days — Orders',
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
                        maxY:
                            (_last7Days
                                        .map((d) => d.count)
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
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= _last7Days.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _last7Days[idx].label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 24,
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
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: _last7Days[i].count.toDouble(),
                                color: AppTheme.primary,
                                width: 22,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY:
                                      (_last7Days
                                                  .map((d) => d.count)
                                                  .reduce(
                                                    (a, b) => a > b ? a : b,
                                                  )
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
              'Last 7 Days — Revenue',
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
                children: List.generate(_last7Days.length, (i) {
                  final day = _last7Days[i];
                  final maxRev = _last7Days
                      .map((d) => d.revenue)
                      .reduce((a, b) => a > b ? a : b);
                  final fraction = maxRev > 0 ? day.revenue / maxRev : 0.0;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      i == 0 ? 12 : 8,
                      16,
                      i == 6 ? 12 : 0,
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