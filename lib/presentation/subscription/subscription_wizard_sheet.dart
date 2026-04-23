import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_profile_notifier.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

// ─── Dish Data for Subscription ──────────────────────────────────────────────

class SubDish {
  final String id;
  final String name;
  final double price;
  final String meal;
  final bool isVeg;

  const SubDish({
    required this.id,
    required this.name,
    required this.price,
    required this.meal,
    this.isVeg = true,
  });
}

const List<String> _mealOrder = ['breakfast', 'lunch', 'dinner'];

List<SubDish> dishesForMeal(String meal) => const <SubDish>[];

const List<String> _weekDays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _weekDayKeys = [
  'mon',
  'tue',
  'wed',
  'thu',
  'fri',
  'sat',
  'sun',
];

// ─── Subscription Wizard ─────────────────────────────────────────────────────

Future<void> showSubscriptionWizard(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SubscriptionWizardSheet(),
  );
}

class _SubscriptionWizardSheet extends StatefulWidget {
  const _SubscriptionWizardSheet();

  @override
  State<_SubscriptionWizardSheet> createState() =>
      _SubscriptionWizardSheetState();
}

class _SubscriptionWizardSheetState extends State<_SubscriptionWizardSheet>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _loadingMenu = true;
  String? _menuError;

  // Step 1 — Date Range
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 29));

  // Step 2 — Meal Selection
  final Set<String> _selectedMeals = {'lunch'};

  // Step 3 — Weekly Plan: { meal: { dayKey: dishId } }
  final Map<String, Map<String, String>> _weeklyPlan = {};
  final Map<String, List<SubDish>> _subscriptionDishesByMeal = {
    for (final meal in _mealOrder) meal: <SubDish>[],
  };

  late AnimationController _stepAnimController;
  late Animation<double> _stepFadeAnim;
  late AnimationController _successController;
  late Animation<double> _successScaleAnim;

  @override
  void initState() {
    super.initState();
    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _stepFadeAnim = CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeOut,
    );
    _stepAnimController.forward();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _initWeeklyPlan();
    unawaited(_loadSubscriptionMenu());
  }

  void _initWeeklyPlan() {
    for (final meal in _mealOrder) {
      _weeklyPlan[meal] = {};
    }
  }

  Future<void> _loadSubscriptionMenu() async {
    setState(() {
      _loadingMenu = true;
      _menuError = null;
    });
    try {
      final rows = await SupabaseService.instance.getMenuItems();
      final grouped = <String, List<SubDish>>{
        for (final meal in _mealOrder) meal: <SubDish>[],
      };

      for (final row in rows) {
        final meal = ((row['meal_type'] as String?) ?? '').trim().toLowerCase();
        if (!_mealOrder.contains(meal)) continue;
        if ((row['available_for_subscription'] as bool?) == false) continue;
        grouped[meal]!.add(
          SubDish(
            id: row['id'] as String,
            name: ((row['name'] as String?) ?? '').trim(),
            price: (row['price'] as num?)?.toDouble() ?? 0,
            meal: meal,
            isVeg: row['is_veg'] as bool? ?? true,
          ),
        );
      }

      for (final meal in _mealOrder) {
        grouped[meal]!.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      }

      final availableMeals = _mealOrder
          .where((meal) => grouped[meal]!.isNotEmpty)
          .toList();
      final nextSelectedMeals = _selectedMeals
          .where(availableMeals.contains)
          .toSet();

      if (nextSelectedMeals.isEmpty && availableMeals.isNotEmpty) {
        nextSelectedMeals.add(
          availableMeals.contains('lunch') ? 'lunch' : availableMeals.first,
        );
      }

      if (!mounted) return;
      setState(() {
        for (final meal in _mealOrder) {
          _subscriptionDishesByMeal[meal] = grouped[meal]!;
        }
        _selectedMeals
          ..clear()
          ..addAll(nextSelectedMeals);
        _ensureWeeklyPlanDefaults();
        _loadingMenu = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menuError = 'Could not load subscription menu.';
        _loadingMenu = false;
      });
    }
  }

  void _ensureWeeklyPlanDefaults() {
    for (final meal in _mealOrder) {
      final dishes = _dishesForMeal(meal);
      final plan = _weeklyPlan.putIfAbsent(meal, () => {});
      if (dishes.isEmpty) {
        plan.clear();
        continue;
      }
      final validIds = dishes.map((dish) => dish.id).toSet();
      for (final day in _weekDayKeys) {
        final currentId = plan[day];
        if (currentId == null || !validIds.contains(currentId)) {
          plan[day] = dishes.first.id;
        }
      }
    }
  }

  List<SubDish> _dishesForMeal(String meal) =>
      _subscriptionDishesByMeal[meal] ?? const <SubDish>[];

  SubDish? _selectedDishForDay(String meal, String dayKey) {
    final dishes = _dishesForMeal(meal);
    if (dishes.isEmpty) return null;
    final selectedDishId = _weeklyPlan[meal]?[dayKey];
    for (final dish in dishes) {
      if (dish.id == selectedDishId) return dish;
    }
    return dishes.first;
  }

  @override
  void dispose() {
    _stepAnimController.dispose();
    _successController.dispose();
    super.dispose();
  }

  int get _totalDays => _endDate.difference(_startDate).inDays + 1;

  double get _weeklyPlanAmount => _selectedMeals.fold(0.0, (sum, meal) {
    final mealTotal = _weekDayKeys.fold(0.0, (daySum, dayKey) {
      return daySum + (_selectedDishForDay(meal, dayKey)?.price ?? 0);
    });
    return sum + mealTotal;
  });

  double get _pricePerDay =>
      _weekDayKeys.isEmpty ? 0 : _weeklyPlanAmount / _weekDayKeys.length;

  double get _totalAmount => _pricePerDay * _totalDays;

  void _goToStep(int step) {
    _stepAnimController.reverse().then((_) {
      setState(() => _step = step);
      _stepAnimController.forward();
    });
  }

  void _nextStep() {
    if (_step < 3) _goToStep(_step + 1);
  }

  void _prevStep() {
    if (_step > 0) _goToStep(_step - 1);
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _endDate.isAfter(_startDate);
      case 1:
        return !_loadingMenu && _menuError == null && _selectedMeals.isNotEmpty;
      case 2:
        return !_loadingMenu &&
            _menuError == null &&
            _selectedMeals.isNotEmpty &&
            _selectedMeals.every((meal) => _dishesForMeal(meal).isNotEmpty);
      case 3:
        return !_loadingMenu &&
            _menuError == null &&
            _selectedMeals.isNotEmpty &&
            _selectedMeals.every((meal) => _dishesForMeal(meal).isNotEmpty);
      default:
        return false;
    }
  }

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    if (_loadingMenu || _menuError != null || _selectedMeals.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = context.read<CustomerProfileNotifier>();
    if (profile.customer == null) {
      await profile.loadFromSupabase();
    }
    final customer = profile.customer;
    final customerId = customer?['id'] as String?;
    final customerName = customer?['name'] as String? ?? '';
    final customerPhone = customer?['phone'] as String? ?? '';

    if (customerId == null ||
        customerId.trim().isEmpty ||
        customerName.trim().isEmpty ||
        customerPhone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer profile not loaded. Open Profile and complete your details.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // Build weekly plan for selected meals only
    final Map<String, dynamic> planToSave = {};
    for (final dayKey in _weekDayKeys) {
      planToSave[dayKey] = {};
      for (final meal in _selectedMeals) {
        planToSave[dayKey][meal] = _weeklyPlan[meal]?[dayKey] ?? '';
      }
    }

    final subscriptionId = await SupabaseService.instance.saveSubscription(
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      startDate: _startDate,
      endDate: _endDate,
      meals: _selectedMeals.toList(),
      weeklyPlan: planToSave,
      totalAmount: _totalAmount,
    );

    if (subscriptionId == null) {
      final errorMessage =
          SupabaseService.instance.lastSubscriptionError ??
          'Unknown subscription creation failure.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = false;
      _showSuccess = true;
    });
    _successController.forward();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      margin: EdgeInsets.only(bottom: bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: _showSuccess ? _buildSuccess() : _buildWizard(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: ScaleTransition(
        scale: _successScaleAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.buttonShadow,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Subscription Active! 🎉',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your meals are on repeat.\nSit back and relax 🍱',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizard() {
    return Column(
      children: [
        _buildHandle(),
        _buildStepIndicator(),
        Expanded(
          child: FadeTransition(
            opacity: _stepFadeAnim,
            child: _buildStepContent(),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.textMuted.withAlpha(80),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final titles = [
      'When should we start?',
      'Which meals do you want?',
      'Plan your weekly menu',
      'Review & Confirm',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              final isActive = i == _step;
              final isDone = i < _step;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: isActive || isDone
                        ? AppTheme.primaryGradient
                        : null,
                    color: isActive || isDone
                        ? null
                        : AppTheme.textMuted.withAlpha(50),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_step + 1} of 4',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titles[_step],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  // ─── Step 1: Date Range ───────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateCard(
            label: 'Start Date',
            icon: Icons.play_circle_outline_rounded,
            date: _startDate,
            onTap: () => _pickDate(isStart: true),
          ),
          const SizedBox(height: 12),
          _buildDateCard(
            label: 'End Date',
            icon: Icons.stop_circle_outlined,
            date: _endDate,
            onTap: () => _pickDate(isStart: false),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: Row(
              children: [
                const Text('🍱', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "That's $_totalDays days of delicious meals!",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDate(_startDate)} → ${_formatDate(_endDate)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildCalendarPreview(),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required IconData icon,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    _formatDateFull(date),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_calendar_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendar Preview',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays.map((d) {
              return Text(
                d,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime(_startDate.year, _startDate.month, 1);
    final firstWeekday = now.weekday;
    final daysInMonth = DateTime(_startDate.year, _startDate.month + 1, 0).day;
    final cells = <Widget>[];

    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_startDate.year, _startDate.month, d);
      final isInRange = !date.isBefore(_startDate) && !date.isAfter(_endDate);
      final isStart =
          date.year == _startDate.year &&
          date.month == _startDate.month &&
          date.day == _startDate.day;
      final isEnd =
          date.year == _endDate.year &&
          date.month == _endDate.month &&
          date.day == _endDate.day;

      cells.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: isStart || isEnd ? AppTheme.primaryGradient : null,
            color: isInRange && !isStart && !isEnd
                ? AppTheme.primary.withAlpha(30)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$d',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isStart || isEnd
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: isStart || isEnd
                    ? Colors.white
                    : isInRange
                    ? AppTheme.primary
                    : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: cells,
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: isStart ? tomorrow : _startDate.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (!_endDate.isAfter(_startDate.add(const Duration(days: 1)))) {
            _endDate = _startDate.add(const Duration(days: 28));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // ─── Step 2: Meal Selection ───────────────────────────────────────────────

  Widget _buildStep2() {
    if (_loadingMenu) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_menuError != null) {
      return _buildMenuLoadState(
        message: _menuError!,
        actionLabel: 'Retry',
        onTap: _loadSubscriptionMenu,
      );
    }

    final meals = [
      {
        'key': 'breakfast',
        'label': 'Breakfast',
        'emoji': '🌅',
        'time': '7:00 – 9:00 AM',
      },
      {
        'key': 'lunch',
        'label': 'Lunch',
        'emoji': '🍛',
        'time': '12:00 – 2:00 PM',
      },
      {
        'key': 'dinner',
        'label': 'Dinner',
        'emoji': '🌙',
        'time': '7:00 – 9:00 PM',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select one or more meal slots',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...meals.map((m) {
            final key = m['key']!;
            final hasDishes = _dishesForMeal(key).isNotEmpty;
            final isSelected = _selectedMeals.contains(key);
            return _MealChipCard(
              emoji: m['emoji']!,
              label: m['label']!,
              time: hasDishes ? m['time']! : 'No subscription dishes available',
              isSelected: isSelected,
              isEnabled: hasDishes,
              onTap: () {
                if (!hasDishes) return;
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected && _selectedMeals.length > 1) {
                    _selectedMeals.remove(key);
                  } else if (!isSelected) {
                    _selectedMeals.add(key);
                  }
                  _ensureWeeklyPlanDefaults();
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // ─── Step 3: Weekly Dish Planner ──────────────────────────────────────────

  Widget _buildStep3() {
    if (_loadingMenu) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_menuError != null) {
      return _buildMenuLoadState(
        message: _menuError!,
        actionLabel: 'Retry',
        onTap: _loadSubscriptionMenu,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This weekly template repeats over your subscription',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedMeals.isEmpty)
            _buildMenuLoadState(
              message: 'No subscription meals are currently available.',
              actionLabel: 'Refresh',
              onTap: _loadSubscriptionMenu,
            ),
          ..._selectedMeals.map((meal) => _buildMealPlanner(meal)),
        ],
      ),
    );
  }

  Widget _buildMealPlanner(String meal) {
    final dishes = _dishesForMeal(meal);
    if (dishes.isEmpty) {
      return const SizedBox.shrink();
    }
    final mealEmoji = meal == 'breakfast'
        ? '🌅'
        : meal == 'lunch'
        ? '🍛'
        : '🌙';
    final mealLabel = meal[0].toUpperCase() + meal.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(mealEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  mealLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_weekDayKeys.length, (i) {
            final dayKey = _weekDayKeys[i];
            final dayLabel = _weekDays[i];
            final selectedDish =
                _selectedDishForDay(meal, dayKey) ?? dishes.first;

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      dayLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showDishPicker(meal, dayKey, dishes),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedDish.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₹${selectedDish.price.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showDishPicker(String meal, String dayKey, List<SubDish> dishes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose a dish',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dishes.length,
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    final isSelected =
                        (_weeklyPlan[meal]?[dayKey] ?? '') == dish.id;
                    return ListTile(
                      onTap: () {
                        setState(() {
                          _weeklyPlan[meal]![dayKey] = dish.id;
                        });
                        Navigator.pop(context);
                      },
                      leading: _VegIndicator(isVeg: dish.isVeg),
                      title: Text(
                        dish.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${dish.price.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 4: Review + Confirm ─────────────────────────────────────────────

  Widget _buildStep4() {
    if (_loadingMenu) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_menuError != null) {
      return _buildMenuLoadState(
        message: _menuError!,
        actionLabel: 'Retry',
        onTap: _loadSubscriptionMenu,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewCard(
            icon: Icons.calendar_today_rounded,
            title: 'Duration',
            content:
                '${_formatDateFull(_startDate)} → ${_formatDateFull(_endDate)}\n$_totalDays days',
          ),
          const SizedBox(height: 10),
          _buildReviewCard(
            icon: Icons.restaurant_rounded,
            title: 'Meals',
            content: _selectedMeals
                .map((m) => m[0].toUpperCase() + m.substring(1))
                .join(' · '),
          ),
          const SizedBox(height: 10),
          Container(
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.view_week_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Weekly Menu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._selectedMeals.map((meal) {
                  final dishes = _dishesForMeal(meal);
                  if (dishes.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final mealLabel = meal[0].toUpperCase() + meal.substring(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _weekDayKeys.map((dayKey) {
                            final dish =
                                _selectedDishForDay(meal, dayKey) ??
                                dishes.first;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dish.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: Column(
              children: [
                _buildPriceLine(
                  '₹${_pricePerDay.toStringAsFixed(0)}/day × $_totalDays days',
                  '₹${_totalAmount.toStringAsFixed(0)}',
                  isTotal: false,
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withAlpha(60), height: 1),
                const SizedBox(height: 8),
                _buildPriceLine(
                  'Total Amount',
                  '₹${_totalAmount.toStringAsFixed(0)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuLoadState({
    required String message,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 42,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceLine(String label, String value, {required bool isTotal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white.withAlpha(isTotal ? 255 : 200),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ─── Bottom Actions ───────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_step > 0)
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withAlpha(40)),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _canProceed ? (_step == 3 ? _subscribe : _nextStep) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: _canProceed ? AppTheme.primaryGradient : null,
                  color: _canProceed ? null : AppTheme.textMuted.withAlpha(60),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _canProceed ? AppTheme.buttonShadow : null,
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_step == 3) ...[
                              const Text('💳', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _step == 3 ? 'Subscribe & Pay' : 'Continue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _canProceed
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                            ),
                            if (_step < 3) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: _canProceed
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _formatDateFull(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Meal Chip Card ───────────────────────────────────────────────────────────

class _VegIndicator extends StatelessWidget {
  final bool isVeg;

  const _VegIndicator({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed;
    return SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _MealChipCard extends StatefulWidget {
  final String emoji;
  final String label;
  final String time;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _MealChipCard({
    required this.emoji,
    required this.label,
    required this.time,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_MealChipCard> createState() => _MealChipCardState();
}

class _MealChipCardState extends State<_MealChipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => _controller.reverse() : null,
      onTapUp: (_) {
        _controller.forward();
        if (widget.isEnabled) {
          widget.onTap();
        }
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient:
                widget.isSelected && widget.isEnabled
                    ? AppTheme.primaryGradient
                    : null,
            color:
                widget.isSelected && widget.isEnabled
                    ? null
                    : widget.isEnabled
                    ? Colors.white
                    : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected && widget.isEnabled
                  ? Colors.transparent
                  : widget.isEnabled
                  ? AppTheme.primary.withAlpha(40)
                  : AppTheme.textMuted.withAlpha(40),
            ),
            boxShadow: widget.isSelected && widget.isEnabled
                ? AppTheme.buttonShadow
                : AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: widget.isSelected && widget.isEnabled
                            ? Colors.white
                            : widget.isEnabled
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      widget.time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: widget.isSelected && widget.isEnabled
                            ? Colors.white.withAlpha(200)
                            : widget.isEnabled
                            ? AppTheme.textSecondary
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: widget.isSelected && widget.isEnabled
                      ? Colors.white
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected && widget.isEnabled
                        ? Colors.white
                        : widget.isEnabled
                        ? AppTheme.textMuted
                        : AppTheme.textMuted.withAlpha(120),
                    width: 2,
                  ),
                ),
                child: widget.isSelected && widget.isEnabled
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
