import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/app_snackbar.dart';
import '../../core/menu_pricing.dart';
import '../../providers/customer_profile_notifier.dart';
import '../customer_main/customer_main_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedAddressIndex = 0;
  String _selectedPayment = 'upi';
  String _selectedUpi = 'gpay';
  bool _isPlacingOrder = false;

  // Order summary from cart (GoRouter extra) or demo defaults
  Map<String, dynamic> _orderData = {};

  final List<Map<String, dynamic>> _addresses = [
    {
      'label': 'Home',
      'icon': Icons.home_rounded,
      'name': 'Meena Krishnan',
      'line1': '14, Lotus Garden, 3rd Cross',
      'line2': 'Anna Nagar, Chennai - 600040',
      'phone': '+91 98765 43210',
    },
    {
      'label': 'Work',
      'icon': Icons.work_rounded,
      'name': 'Meena Krishnan',
      'line1': '7th Floor, Prestige Tower',
      'line2': 'Nungambakkam, Chennai - 600034',
      'phone': '+91 98765 43210',
    },
  ];

  final List<Map<String, dynamic>> _upiOptions = [
    {
      'id': 'gpay',
      'name': 'Google Pay',
      'icon': Icons.g_mobiledata_rounded,
      'color': Color(0xFF4285F4),
    },
    {
      'id': 'phonepe',
      'name': 'PhonePe',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF5F259F),
    },
    {
      'id': 'paytm',
      'name': 'Paytm',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF00BAF2),
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      _orderData = Map<String, dynamic>.from(extra);
    } else if (_orderData.isEmpty) {
      _orderData = {
        'items': [
          {'name': "Amma's Dal Tadka", 'qty': 2, 'price': 120.0, 'isVeg': true},
          {'name': 'Chicken Biryani', 'qty': 1, 'price': 220.0, 'isVeg': false},
          {'name': 'Filter Coffee', 'qty': 2, 'price': 120.0, 'isVeg': true},
        ],
        'subtotal': 535.0,
        'deliveryFee': 0.0,
        'discount': 53.5,
        'gst': 24.08,
        'total': 505.58,
        'couponCode': 'MENAKA50',
      };
    }
  }

  double get _total => (_orderData['total'] as num?)?.toDouble() ?? 0.0;

  Future<void> _placeOrder() async {
    if (_selectedPayment == 'upi' && _selectedUpi == 'gpay') {
      await _payWithGPay();
      return;
    }
    setState(() => _isPlacingOrder = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() => _isPlacingOrder = false);
      context.go('/order-success');
    }
  }

  /// Google Pay UPI deep link, then persist order in Supabase.
  Future<void> _payWithGPay() async {
    final profile = context.read<CustomerProfileNotifier>();
    final customerId = profile.customerId;
    final customerRow = profile.customer;
    if (customerId == null || customerRow == null) {
      showErrorSnackbar(context, 'Customer profile not loaded. Open Profile.');
      return;
    }

    final total = _total;
    final uri = Uri.parse(
      'upi://pay?pa=menakahomefoods@okicici'
      '&pn=MenakaHomeFoods'
      '&am=${total.toStringAsFixed(2)}'
      '&cu=INR'
      '&tn=MenakaHomeFoodsOrder',
    );

    if (await canLaunchUrl(uri)) {
      setState(() => _isPlacingOrder = true);
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      final itemsRaw = (_orderData['items'] as List?) ?? [];
      final cartItemsJson =
          itemsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      try {
        await Supabase.instance.client.from('orders').insert({
          'customer_id': customerId,
          'customer_name': customerRow['name'] ?? '',
          'customer_address': profile.formattedAddress(),
          'items': cartItemsJson,
          'subtotal': (_orderData['subtotal'] as num?)?.toDouble() ?? 0,
          'delivery_fee': (_orderData['deliveryFee'] as num?)?.toDouble() ?? 0,
          'gst': (_orderData['gst'] as num?)?.toDouble() ?? 0,
          'discount': (_orderData['discount'] as num?)?.toDouble() ?? 0,
          'coupon_code': _orderData['couponCode'] ?? '',
          'total': total,
          'payment_method': 'gpay',
          'payment_status': 'paid',
          'status': 'placed',
        });
        CartState.instance.clear();
        if (mounted) {
          setState(() => _isPlacingOrder = false);
          context.go('/order-success');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isPlacingOrder = false);
          showErrorSnackbar(context, 'Could not save order: $e');
        }
      }
    } else {
      if (mounted) {
        showErrorSnackbar(
          context,
          'GPay not installed. Please install GPay and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSectionTitle(
                    'Delivery Address',
                    Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 10),
                  ..._addresses.asMap().entries.map(
                    (e) => _buildAddressCard(e.key, e.value),
                  ),
                  _buildAddNewAddress(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Payment Method', Icons.payment_rounded),
                  const SizedBox(height: 10),
                  _buildPaymentOptions(),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    'Order Summary',
                    Icons.receipt_long_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Checkout',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Review & confirm your order',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withAlpha(217),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${_total.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(int index, Map<String, dynamic> address) {
    final isSelected = _selectedAddressIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFEDD5C8),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryContainer
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                address['icon'] as IconData,
                size: 18,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryContainer
                              : AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          address['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        address['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address['line1'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    address['line2'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        address['phone'] as String,
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
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewAddress() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDD5C8), width: 1.5),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_location_alt_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add New Address',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        // UPI Option
        _buildPaymentTile(
          id: 'upi',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF7C3AED),
          iconBg: const Color(0xFFF3E8FF),
          title: 'UPI Payment',
          subtitle: 'Pay via Google Pay, PhonePe, Paytm',
          child: _selectedPayment == 'upi' ? _buildUpiOptions() : null,
        ),
        const SizedBox(height: 10),
        // Card Option
        _buildPaymentTile(
          id: 'card',
          icon: Icons.credit_card_rounded,
          iconColor: const Color(0xFF0369A1),
          iconBg: const Color(0xFFE0F2FE),
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard, RuPay accepted',
          child: _selectedPayment == 'card' ? _buildCardForm() : null,
        ),
        const SizedBox(height: 10),
        // COD Option
        _buildPaymentTile(
          id: 'cod',
          icon: Icons.payments_rounded,
          iconColor: AppTheme.success,
          iconBg: AppTheme.successLight,
          title: 'Cash on Delivery',
          subtitle: 'Pay when your order arrives',
        ),
      ],
    );
  }

  Widget _buildPaymentTile({
    required String id,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    Widget? child,
  }) {
    final isSelected = _selectedPayment == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFEDD5C8),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFFD4B5A0),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
            if (child != null) ...[
              const Divider(height: 1, color: Color(0xFFEDD5C8)),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpiOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Row(
        children: _upiOptions.map((upi) {
          final isSelected = _selectedUpi == upi['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedUpi = upi['id'] as String),
              child: Container(
                margin: EdgeInsets.only(
                  right: upi['id'] != _upiOptions.last['id'] ? 8 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryContainer
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      upi['icon'] as IconData,
                      size: 22,
                      color: upi['color'] as Color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      upi['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          _buildCardInput(hint: 'Card Number', icon: Icons.credit_card_rounded),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCardInput(
                  hint: 'MM / YY',
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCardInput(hint: 'CVV', icon: Icons.lock_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCardInput(hint: 'Cardholder Name', icon: Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _buildCardInput({required String hint, required IconData icon}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDD5C8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 15, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final items =
        (_orderData['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final subtotal = (_orderData['subtotal'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (_orderData['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final discount = (_orderData['discount'] as num?)?.toDouble() ?? 0.0;
    final gst = (_orderData['gst'] as num?)?.toDouble() ?? 0.0;
    final total = (_orderData['total'] as num?)?.toDouble() ?? 0.0;
    final coupon = _orderData['couponCode'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Items list
          ...items.map((item) {
            final isVeg = item['isVeg'] as bool? ?? true;
            final lineTotal = getPrice(isVeg) * ((item['qty'] as num?)?.toDouble() ?? 1);
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item['name']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '×${item['qty']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '₹${lineTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEDD5C8)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildPriceRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                if (deliveryFee == 0)
                  _buildPriceRow(
                    'Delivery',
                    'FREE',
                    valueColor: AppTheme.success,
                  )
                else
                  _buildPriceRow(
                    'Delivery',
                    '₹${deliveryFee.toStringAsFixed(0)}',
                  ),
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  _buildPriceRow(
                    coupon.isNotEmpty ? 'Coupon ($coupon)' : 'Discount',
                    '-₹${discount.toStringAsFixed(0)}',
                    valueColor: AppTheme.success,
                  ),
                ],
                const SizedBox(height: 6),
                _buildPriceRow('GST (5%)', '₹${gst.toStringAsFixed(0)}'),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEDD5C8)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
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

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: _isPlacingOrder ? null : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isPlacingOrder
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Placing Order...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Confirm Order',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(64),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${_total.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
