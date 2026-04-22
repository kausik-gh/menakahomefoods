import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../core/app_localizations.dart';
import '../../services/supabase_service.dart';
import './widgets/tracking_map_widget.dart';
import './widgets/tracking_order_summary_widget.dart';
import './widgets/tracking_partner_card_widget.dart';
import './widgets/tracking_status_timeline_widget.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _emptyBounceController;
  late Animation<double> _emptyBounceAnim;

  Map<String, dynamic>? _activeOrder;
  Map<String, dynamic>? _activeSubscription;
  bool _isLoading = true;
  bool _ratingShown = false;
  RealtimeChannel? _realtimeChannel;

  int get _currentStep {
    final status = _activeOrder?['status'] as String? ?? '';
    switch (status) {
      case 'placed':
        return 0;
      case 'confirmed':
        return 1;
      case 'preparing':
        return 1;
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _emptyBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _emptyBounceAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _emptyBounceController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emptyBounceController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final authId = user?.id;
      String customerId = '';
      if (authId != null) {
        final row = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('id', authId)
            .maybeSingle();
        customerId = row?['id'] as String? ?? '';
      }

      final orderFuture = Supabase.instance.client
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .not('status', 'eq', 'delivered')
          .not('status', 'eq', 'cancelled')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final subFuture = SupabaseService.instance.getActiveSubscription(
        customerId,
      );

      final results = await Future.wait([orderFuture, subFuture]);

      if (mounted) {
        setState(() {
          _activeOrder = results[0];
          _activeSubscription = results[1];
          _isLoading = false;
        });
        if (_activeOrder != null) {
          _subscribeToOrder(_activeOrder!['id'] as String);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToOrder(String orderId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('order_track_$orderId')
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
            if (mounted) {
              final updated = payload.newRecord;
              setState(() => _activeOrder = updated);
              if (updated['status'] == 'delivered' && !_ratingShown) {
                _ratingShown = true;
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) _showRatingModal();
                });
              }
            }
          },
        )
        .subscribe();
  }

  void _showRatingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RateMealModal(
        orderId: _activeOrder?['id'] as String? ?? '',
        onSubmit: (rating, comment) {
          Navigator.pop(context);
          _saveRating(rating, comment);
        },
      ),
    );
  }

  Future<void> _saveRating(int rating, String comment) async {
    try {
      final orderId = _activeOrder?['id'] as String?;
      if (orderId == null) return;
      await Supabase.instance.client
          .from('orders')
          .update({'rating': rating, 'rating_comment': comment})
          .eq('id', orderId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      appBar: _buildAppBar(loc),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? _buildLoadingState(loc)
            : _activeOrder != null
            ? _buildActiveOrder()
            : _activeSubscription != null
            ? _buildSubscriptionState(loc)
            : _buildEmptyState(loc),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations loc) {
    final orderId = _activeOrder?['id'] as String?;
    final shortId = orderId != null && orderId.length >= 8
        ? 'MHF-${orderId.substring(0, 8).toUpperCase()}'
        : null;

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.t('track_order'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (shortId != null)
                        Text(
                          'Order #$shortId',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withAlpha(217),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_activeOrder != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentStep >= 3
                              ? loc.t('delivered')
                              : '~20 ${loc.t('min')}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('checking_orders'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _emptyBounceAnim,
              builder: (context, child) =>
                  Transform.scale(scale: _emptyBounceAnim.value, child: child),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('🍜', style: TextStyle(fontSize: 64)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              loc.t('nothing_on_way'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              loc.t('no_orders_subtext'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.buttonShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.restaurant_menu_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.t('order_now'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(80),
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.repeat_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.t('subscribe'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrder() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          TrackingMapWidget(
            currentStep: _currentStep,
            pulseController: _pulseController,
            riderLat: (_activeOrder?['rider_lat'] as num?)?.toDouble(),
            riderLng: (_activeOrder?['rider_lng'] as num?)?.toDouble(),
            customerLat: (_activeOrder?['customer_lat'] as num?)?.toDouble(),
            customerLng: (_activeOrder?['customer_lng'] as num?)?.toDouble(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TrackingStatusTimelineWidget(
              currentStep: _currentStep,
              pulseController: _pulseController,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TrackingPartnerCardWidget(
              currentStep: _currentStep,
              riderName: _activeOrder?['rider_name'] as String?,
              riderPhone: _activeOrder?['rider_phone'] as String?,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TrackingOrderSummaryWidget(order: _activeOrder!),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSubscriptionState(AppLocalizations loc) {
    final sub = _activeSubscription!;
    final startDate =
        DateTime.tryParse(sub['start_date'] as String? ?? '') ?? DateTime.now();
    final endDate =
        DateTime.tryParse(sub['end_date'] as String? ?? '') ?? DateTime.now();
    final now = DateTime.now();
    final totalDays = endDate.difference(startDate).inDays + 1;
    final currentDay = now.difference(startDate).inDays + 1;
    final daysRemaining = endDate.difference(now).inDays + 1;
    final progress = (currentDay / totalDays).clamp(0.0, 1.0);

    final meals = List<String>.from(sub['meals'] as List? ?? []);
    final today = _getTodayKey();
    final weeklyPlan = sub['weekly_plan'] as Map<String, dynamic>? ?? {};
    final todayPlan = weeklyPlan[today] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Subscription Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.repeat_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.t('active_subscription'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Active',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Days progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day $currentDay of $totalDays',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                    Text(
                      '$daysRemaining days left',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Today's Meals
          Text(
            loc.t('todays_meals'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...meals.map((meal) {
            final dishName = todayPlan[meal] as String? ?? meal;
            return _TodayMealCard(meal: meal, dishName: dishName, loc: loc);
          }),
          const SizedBox(height: 20),

          // Edit Today's Dish button
          _EditDishButton(loc: loc),
        ],
      ),
    );
  }

  String _getTodayKey() {
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[DateTime.now().weekday - 1];
  }
}

// ─── Today Meal Card ──────────────────────────────────────────────────────────

class _TodayMealCard extends StatelessWidget {
  final String meal;
  final String dishName;
  final AppLocalizations loc;

  const _TodayMealCard({
    required this.meal,
    required this.dishName,
    required this.loc,
  });

  String _mealEmoji(String meal) {
    switch (meal) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '🍛';
      case 'dinner':
        return '🌙';
      default:
        return '🍽️';
    }
  }

  String _mealLabel(String meal, AppLocalizations loc) {
    switch (meal) {
      case 'breakfast':
        return loc.t('breakfast');
      case 'lunch':
        return loc.t('lunch');
      case 'dinner':
        return loc.t('dinner');
      default:
        return meal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Text(_mealEmoji(meal), style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mealLabel(meal, loc),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  dishName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              loc.t('upcoming'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Dish Button with 2-hour countdown ───────────────────────────────────

class _EditDishButton extends StatefulWidget {
  final AppLocalizations loc;
  const _EditDishButton({required this.loc});

  @override
  State<_EditDishButton> createState() => _EditDishButtonState();
}

class _EditDishButtonState extends State<_EditDishButton> {
  Timer? _timer;
  Duration _timeUntilClose = Duration.zero;
  bool _editEnabled = true;

  @override
  void initState() {
    super.initState();
    _calculateEditWindow();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _calculateEditWindow();
    });
  }

  void _calculateEditWindow() {
    final now = DateTime.now();
    // Breakfast closes at 7:30 AM, Lunch at 11:30 AM, Dinner at 5:30 PM
    final hour = now.hour;
    DateTime? closeTime;

    if (hour < 7 || (hour == 7 && now.minute < 30)) {
      closeTime = DateTime(now.year, now.month, now.day, 7, 30);
    } else if (hour < 11 || (hour == 11 && now.minute < 30)) {
      closeTime = DateTime(now.year, now.month, now.day, 11, 30);
    } else if (hour < 17 || (hour == 17 && now.minute < 30)) {
      closeTime = DateTime(now.year, now.month, now.day, 17, 30);
    }

    if (closeTime != null) {
      final diff = closeTime.difference(now);
      setState(() {
        _timeUntilClose = diff;
        _editEnabled = diff.inMinutes > 120; // 2 hours
      });
    } else {
      setState(() {
        _editEnabled = false;
        _timeUntilClose = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return Column(
      children: [
        GestureDetector(
          onTap: _editEnabled ? () {} : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: _editEnabled ? AppTheme.primaryGradient : null,
              color: _editEnabled ? null : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _editEnabled ? AppTheme.buttonShadow : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_rounded,
                  color: _editEnabled ? Colors.white : AppTheme.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.t('edit_today_dish'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _editEnabled ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_editEnabled && _timeUntilClose.inMinutes > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${loc.t('edit_closes_in')} ${_formatCountdown(_timeUntilClose)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.warning,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ─── Rate Meal Modal ──────────────────────────────────────────────────────────

class _RateMealModal extends StatefulWidget {
  final String orderId;
  final void Function(int rating, String comment) onSubmit;

  const _RateMealModal({required this.orderId, required this.onSubmit});

  @override
  State<_RateMealModal> createState() => _RateMealModalState();
}

class _RateMealModalState extends State<_RateMealModal>
    with SingleTickerProviderStateMixin {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _starController;
  late List<Animation<double>> _starAnims;

  static const List<String> _labels = [
    '',
    'Terrible 😞',
    'Not great 😕',
    'It was okay 😐',
    'Really good 😊',
    'Absolutely loved it! 🤩',
  ];

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starAnims = List.generate(
      5,
      (i) => Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(
          parent: _starController,
          curve: Interval(i * 0.1, 0.5 + i * 0.1, curve: Curves.elasticOut),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _starController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onStarTap(int rating) {
    HapticFeedback.lightImpact();
    setState(() => _selectedRating = rating);
    _starController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Your meal was delivered!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How was your Menaka Home Foods experience?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return GestureDetector(
                onTap: () => _onStarTap(starIndex),
                child: AnimatedBuilder(
                  animation: _starAnims[i],
                  builder: (context, child) => Transform.scale(
                    scale: starIndex <= _selectedRating
                        ? _starAnims[i].value
                        : 1.0,
                    child: child,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      starIndex <= _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 44,
                      color: starIndex <= _selectedRating
                          ? AppTheme.ratingGold
                          : const Color(0xFFD0D0D0),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          if (_selectedRating > 0)
            AnimatedOpacity(
              opacity: _selectedRating > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _labels[_selectedRating],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _commentController,
              maxLines: 3,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Tell us more about your experience (optional)...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _selectedRating > 0
                ? () => widget.onSubmit(
                    _selectedRating,
                    _commentController.text.trim(),
                  )
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: _selectedRating > 0 ? AppTheme.primaryGradient : null,
                color: _selectedRating == 0 ? const Color(0xFFE0E0E0) : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedRating > 0
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Submit Rating',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _selectedRating > 0
                        ? Colors.white
                        : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Skip for now',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
