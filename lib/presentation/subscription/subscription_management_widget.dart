import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import './subscription_wizard_sheet.dart';

class SubscriptionManagementWidget extends StatefulWidget {
  const SubscriptionManagementWidget({super.key});

  @override
  State<SubscriptionManagementWidget> createState() =>
      _SubscriptionManagementWidgetState();
}

class _SubscriptionManagementWidgetState
    extends State<SubscriptionManagementWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() => _isLoading = true);
    final sub = await SupabaseService.instance.getActiveSubscription(
      'guest_customer',
    );
    setState(() {
      _subscription = sub;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_subscription == null) {
      return _buildNoSubscription();
    }

    return _buildActiveSubscription();
  }

  Widget _buildNoSubscription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            'No Active Subscription',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Subscribe to get meals delivered daily without ordering every time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => showSubscriptionWizard(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: Text(
                'Start Subscription',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscription() {
    final sub = _subscription!;
    final startDate =
        DateTime.tryParse(sub['start_date'] ?? '') ?? DateTime.now();
    final endDate = DateTime.tryParse(sub['end_date'] ?? '') ?? DateTime.now();
    final now = DateTime.now();
    final totalDays = endDate.difference(startDate).inDays + 1;
    final daysElapsed = now.difference(startDate).inDays;
    final daysRemaining = endDate.difference(now).inDays + 1;
    final progress = (daysElapsed / totalDays).clamp(0.0, 1.0);
    final status = sub['status'] ?? 'active';
    final isPaused = status == 'paused';
    final meals = List<String>.from(sub['meals'] ?? []);
    final weeklyPlan = Map<String, dynamic>.from(sub['weekly_plan'] ?? {});

    // Get today's day key
    final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final todayKey = dayKeys[now.weekday - 1];
    final todayPlan = Map<String, dynamic>.from(weeklyPlan[todayKey] ?? {});

    return Column(
      children: [
        // Header card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.buttonShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🍱', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Active Subscription',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$daysRemaining days remaining',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% complete',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withAlpha(40),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_formatDate(startDate)} → ${_formatDate(endDate)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Today's meals
        if (todayPlan.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.today_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Today's Meals",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...meals.map((meal) {
                  final dishId = todayPlan[meal] ?? '';
                  final dishes = dishesForMeal(meal);
                  final dish = dishes.firstWhere(
                    (d) => d.id == dishId,
                    orElse: () => dishes.isNotEmpty
                        ? dishes.first
                        : SubDish(id: '', name: 'TBD', price: 0, meal: meal),
                  );
                  final mealEmoji = meal == 'breakfast'
                      ? '🌅'
                      : meal == 'lunch'
                      ? '🍛'
                      : '🌙';
                  final editDeadline = _getEditDeadline(meal);
                  final canEdit = DateTime.now().isBefore(editDeadline);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(mealEmoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal[0].toUpperCase() + meal.substring(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                dish.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!canEdit)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warningLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Edit closed',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.warning,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Edit by ${_formatTime(editDeadline)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Actions
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              // Edit this week's dishes
              _ActionTile(
                icon: Icons.edit_calendar_rounded,
                label: "Edit this week's dishes",
                color: AppTheme.deliveryBlue,
                onTap: () => showSubscriptionWizard(context),
              ),
              Divider(height: 1, indent: 60, color: AppTheme.background),

              // Pause toggle
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPaused ? 'Resume Subscription' : 'Pause Subscription',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: !isPaused,
                      onChanged: (val) async {
                        HapticFeedback.selectionClick();
                        final newStatus = val ? 'active' : 'paused';
                        await SupabaseService.instance.updateSubscriptionStatus(
                          sub['id'],
                          newStatus,
                        );
                        _loadSubscription();
                      },
                      activeThumbColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, indent: 60, color: AppTheme.background),

              // Cancel
              _ActionTile(
                icon: Icons.cancel_outlined,
                label: 'Cancel Subscription',
                color: AppTheme.error,
                onTap: () => _showCancelDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DateTime _getEditDeadline(String meal) {
    final now = DateTime.now();
    switch (meal) {
      case 'breakfast':
        return DateTime(now.year, now.month, now.day, 7, 30);
      case 'lunch':
        return DateTime(now.year, now.month, now.day, 10, 0);
      case 'dinner':
        return DateTime(now.year, now.month, now.day, 17, 0);
      default:
        return DateTime(now.year, now.month, now.day, 8, 0);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  String _formatDate(DateTime d) {
    const months = [
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
    return '${d.day} ${months[d.month - 1]}';
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Subscription?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Your subscription will be cancelled immediately. This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep it',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.instance.updateSubscriptionStatus(
                _subscription!['id'],
                'cancelled',
              );
              _loadSubscription();
            },
            child: Text(
              'Cancel Subscription',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'active':
        bg = Colors.white.withAlpha(40);
        fg = Colors.white;
        label = '● Active';
        break;
      case 'paused':
        bg = AppTheme.warningLight;
        fg = AppTheme.warning;
        label = '⏸ Paused';
        break;
      case 'cancelled':
        bg = AppTheme.errorLight;
        fg = AppTheme.error;
        label = '✕ Cancelled';
        break;
      default:
        bg = Colors.white.withAlpha(40);
        fg = Colors.white;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textMuted,
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
