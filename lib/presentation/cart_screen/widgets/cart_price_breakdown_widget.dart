import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CartPriceBreakdownWidget extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double gst;
  final double total;
  final String couponCode;

  const CartPriceBreakdownWidget({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.gst,
    required this.total,
    required this.couponCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bill Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFC8E6C9)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _BillRow(
                  label: 'Item Total',
                  value: '₹${subtotal.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 10),
                _BillRow(
                  label: 'Delivery Fee',
                  value: deliveryFee == 0
                      ? 'FREE 🎉'
                      : '₹${deliveryFee.toStringAsFixed(0)}',
                  valueColor: deliveryFee == 0 ? AppTheme.success : null,
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 10),
                  _BillRow(
                    label: 'Discount ($couponCode)',
                    value: '- ₹${discount.toStringAsFixed(0)}',
                    valueColor: AppTheme.success,
                    icon: Icons.local_offer_rounded,
                  ),
                ],
                const SizedBox(height: 10),
                _BillRow(
                  label: 'GST & Charges (5%)',
                  value: '₹${gst.toStringAsFixed(0)}',
                  labelColor: AppTheme.textMuted,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFC8E6C9),
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'To Pay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (deliveryFee == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    size: 14,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Free delivery on this order!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color? labelColor;
  final IconData? icon;

  const _BillRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: labelColor ?? AppTheme.textSecondary),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: labelColor ?? AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
