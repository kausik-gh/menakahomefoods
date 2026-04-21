import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum OrderStatus {
  placed,
  accepted,
  preparing,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsets? padding;
  final IconData? icon;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 11,
    this.padding,
    this.icon,
  });

  factory StatusBadgeWidget.fromOrderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return StatusBadgeWidget(
          label: 'Order Placed',
          backgroundColor: const Color(0xFFFEF3C7),
          textColor: const Color(0xFFB45309),
          icon: Icons.receipt_rounded,
        );
      case OrderStatus.accepted:
        return StatusBadgeWidget(
          label: 'Accepted',
          backgroundColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF2D7A4F),
          icon: Icons.check_circle_rounded,
        );
      case OrderStatus.preparing:
        return StatusBadgeWidget(
          label: 'Preparing',
          backgroundColor: const Color(0xFFFFE0CC),
          textColor: const Color(0xFFD4521A),
          icon: Icons.restaurant_rounded,
        );
      case OrderStatus.pickedUp:
        return StatusBadgeWidget(
          label: 'Picked Up',
          backgroundColor: const Color(0xFFEDE9FE),
          textColor: const Color(0xFF7C3AED),
          icon: Icons.delivery_dining_rounded,
        );
      case OrderStatus.onTheWay:
        return StatusBadgeWidget(
          label: 'On The Way',
          backgroundColor: const Color(0xFFDBEAFE),
          textColor: const Color(0xFF1D4ED8),
          icon: Icons.two_wheeler_rounded,
        );
      case OrderStatus.delivered:
        return StatusBadgeWidget(
          label: 'Delivered',
          backgroundColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF2D7A4F),
          icon: Icons.check_circle_outline_rounded,
        );
      case OrderStatus.cancelled:
        return StatusBadgeWidget(
          label: 'Cancelled',
          backgroundColor: const Color(0xFFFEE2E2),
          textColor: const Color(0xFFB91C1C),
          icon: Icons.cancel_rounded,
        );
    }
  }

  factory StatusBadgeWidget.veg() {
    return const StatusBadgeWidget(
      label: 'Veg',
      backgroundColor: Color(0xFFDCFCE7),
      textColor: Color(0xFF22C55E),
      icon: Icons.circle,
    );
  }

  factory StatusBadgeWidget.nonVeg() {
    return const StatusBadgeWidget(
      label: 'Non-Veg',
      backgroundColor: Color(0xFFFEE2E2),
      textColor: Color(0xFFEF4444),
      icon: Icons.change_history_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
