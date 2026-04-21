import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class _TrackingStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final String emoji;

  const _TrackingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emoji,
  });
}

class TrackingStatusTimelineWidget extends StatefulWidget {
  final int currentStep;
  final AnimationController pulseController;

  const TrackingStatusTimelineWidget({
    super.key,
    required this.currentStep,
    required this.pulseController,
  });

  @override
  State<TrackingStatusTimelineWidget> createState() =>
      _TrackingStatusTimelineWidgetState();
}

class _TrackingStatusTimelineWidgetState
    extends State<TrackingStatusTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  int _lastStep = -1;

  static const List<_TrackingStep> _steps = [
    _TrackingStep(
      title: 'Order Placed',
      subtitle: 'We received your order',
      icon: Icons.receipt_long_rounded,
      emoji: '✅',
    ),
    _TrackingStep(
      title: 'Confirmed & Preparing',
      subtitle: 'Our chefs are cooking',
      icon: Icons.restaurant_rounded,
      emoji: '🔄',
    ),
    _TrackingStep(
      title: 'Out for Delivery',
      subtitle: 'On the way to you',
      icon: Icons.two_wheeler_rounded,
      emoji: '🛵',
    ),
    _TrackingStep(
      title: 'Delivered',
      subtitle: 'Enjoy your meal!',
      icon: Icons.home_rounded,
      emoji: '🏠',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _lastStep = widget.currentStep;
  }

  @override
  void didUpdateWidget(TrackingStatusTimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != _lastStep) {
      _checkController.forward(from: 0);
      _lastStep = widget.currentStep;
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  Icons.timeline_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Order Status',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: widget.currentStep >= 3
                      ? AppTheme.successLight
                      : AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.currentStep >= 3 ? '✅ Delivered' : '🔄 Live',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.currentStep >= 3
                        ? AppTheme.success
                        : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Steps
          ...List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isCompleted = index < widget.currentStep;
            final isActive = index == widget.currentStep;
            final isPending = index > widget.currentStep;
            final isLast = index == _steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline column
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      // Step indicator
                      if (isActive)
                        AnimatedBuilder(
                          animation: widget.pulseController,
                          builder: (context, child) {
                            final glow = widget.pulseController.value;
                            return SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow ring
                                  Container(
                                    width: 36 + glow * 8,
                                    height: 36 + glow * 8,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.18 * (1 - glow),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // Inner circle
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withAlpha(
                                            (80 + (glow * 60).toInt()),
                                          ),
                                          blurRadius: 8 + glow * 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        step.emoji,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else if (isCompleted)
                        ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _checkController,
                            curve: Curves.elasticOut,
                          ),
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.only(left: 5),
                            decoration: const BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              step.emoji,
                              style: TextStyle(
                                fontSize: 12,
                                color: isPending
                                    ? AppTheme.textMuted
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      // Connector line
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            gradient: isCompleted
                                ? const LinearGradient(
                                    colors: [
                                      AppTheme.success,
                                      Color(0xFFDCFCE7),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: isCompleted ? null : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Step content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isActive || isCompleted
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isPending
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (!isLast) const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
