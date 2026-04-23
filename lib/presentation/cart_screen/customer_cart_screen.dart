import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../services/supabase_service.dart';
import '../customer_main/customer_main_screen.dart';

class CustomerCartScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const CustomerCartScreen({super.key, required this.onNavigate});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    CartState.instance.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartState.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  double get _subtotal => CartState.instance.subtotal;
  double get _deliveryFee => _subtotal >= 300 ? 0 : 29.0;
  double get _gst => _subtotal * 0.05;
  double get _total => _subtotal + _deliveryFee + _gst;

  Future<void> _handlePayNow() async {
    if (_isPlacingOrder) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPlacingOrder = true);

    // Determine primary meal type from cart items
    final mealCounts = <String, int>{};
    for (final item in CartState.instance.items.values) {
      mealCounts[item.meal] = (mealCounts[item.meal] ?? 0) + item.quantity;
    }
    final primaryMeal = mealCounts.entries.isEmpty
        ? 'lunch'
        : mealCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final items = CartState.instance.items.values
        .map(
          (d) => {
            'dish_id': d.id,
            'name': d.name,
            'price': d.price,
            'qty': d.quantity,
          },
        )
        .toList();

    // Save to Supabase
    await SupabaseService.instance.saveOrder(
      customerId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      customerName: 'Guest Customer',
      customerPhone: '9999999999',
      customerAddress: 'Home',
      items: items,
      orderType: 'one_time',
      meal: primaryMeal,
      subtotal: _subtotal,
      deliveryFee: _deliveryFee,
      gst: _gst,
      total: _total,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    // Clear cart and show order placed animation
    CartState.instance.clear();
    await _showOrderPlacedAnimation();
  }

  Future<void> _showOrderPlacedAnimation() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(180),
      pageBuilder: (context, anim1, anim2) => const _OrderPlacedOverlay(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = CartState.instance.items.values.toList();
    final isEmpty = items.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isEmpty
                  ? _buildEmpty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        ...items.map(
                          (item) => _CartItemCard(
                            item: item,
                            onAdd: () => CartState.instance.addItem(item),
                            onRemove: () =>
                                CartState.instance.removeItem(item.id),
                            onDelete: () =>
                                CartState.instance.deleteItem(item.id),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPriceBreakdown(),
                        const SizedBox(height: 16),
                        _buildPayButton(),
                        const SizedBox(height: 100),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Cart',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  CartState.instance.totalCount > 0
                      ? '${CartState.instance.totalCount} item${CartState.instance.totalCount > 1 ? 's' : ''}'
                      : 'Your cart is empty',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (CartState.instance.totalCount > 0)
            GestureDetector(
              onTap: () {
                CartState.instance.clear();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Clear All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add delicious dishes to get started',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => widget.onNavigate(0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: Text(
                'Browse Menu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
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

  Widget _buildPriceBreakdown() {
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
            'Price Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _PriceRow(
            label: 'Subtotal',
            value: '₹${_subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Delivery Fee',
            value: _deliveryFee == 0
                ? 'FREE'
                : '₹${_deliveryFee.toStringAsFixed(2)}',
            valueColor: _deliveryFee == 0 ? AppTheme.success : null,
          ),
          const SizedBox(height: 8),
          _PriceRow(label: 'GST (5%)', value: '₹${_gst.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '₹${_total.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          if (_deliveryFee == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_rounded,
                      size: 14,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Free delivery on orders above ₹300',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return GestureDetector(
      onTap: _isPlacingOrder ? null : _handlePayNow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: _isPlacingOrder ? null : AppTheme.primaryGradient,
          color: _isPlacingOrder ? AppTheme.textMuted : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPlacingOrder ? [] : AppTheme.buttonShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isPlacingOrder)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else ...[
              const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Pay Now  ₹${_total.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
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
}

class _CartItemCard extends StatelessWidget {
  final CartDish item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: SizedBox(
              width: 90,
              height: 90,
              child: CustomImageWidget(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                semanticLabel: item.semanticLabel,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: item.isVeg
                                ? AppTheme.vegGreen
                                : AppTheme.nonVegRed,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: item.isVeg
                                  ? AppTheme.vegGreen
                                  : AppTheme.nonVegRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${item.price.toInt()} each',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.remove_rounded,
                                color: AppTheme.primary,
                                size: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Center(
                              child: Text(
                                '${item.quantity}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onAdd,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Placed Overlay ─────────────────────────────────────────────────────

class _OrderPlacedOverlay extends StatefulWidget {
  const _OrderPlacedOverlay();

  @override
  State<_OrderPlacedOverlay> createState() => _OrderPlacedOverlayState();
}

class _OrderPlacedOverlayState extends State<_OrderPlacedOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  final List<_ConfettiPiece> _confetti = [];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(parent: _scaleController, curve: Curves.easeIn);

    // Generate confetti pieces
    for (int i = 0; i < 30; i++) {
      _confetti.add(
        _ConfettiPiece(
          x: (i * 37.0) % 300,
          color: [
            AppTheme.primary,
            AppTheme.accent,
            AppTheme.vegGreen,
            Colors.purple,
            Colors.blue,
          ][i % 5],
          size: 6.0 + (i % 4) * 2,
          speed: 0.5 + (i % 5) * 0.3,
        ),
      );
    }

    _scaleController.forward();
    _confettiController.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Confetti
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return Stack(
                children: _confetti.map((piece) {
                  final progress = (_confettiController.value * piece.speed)
                      .clamp(0.0, 1.0);
                  final top =
                      -20.0 +
                      progress * (MediaQuery.of(context).size.height + 40);
                  return Positioned(
                    left: piece.x,
                    top: top,
                    child: Transform.rotate(
                      angle: progress * 6.28 * 2,
                      child: Container(
                        width: piece.size,
                        height: piece.size,
                        decoration: BoxDecoration(
                          color: piece.color.withAlpha(200),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          // Main card
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(40),
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.buttonShadow,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Order Placed! 🎉',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your delicious meal is being\nprepared with love ❤️',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Estimated delivery: 30-45 min',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
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
          ),
        ],
      ),
    );
  }
}

class _ConfettiPiece {
  final double x, size, speed;
  final Color color;
  const _ConfettiPiece({
    required this.x,
    required this.color,
    required this.size,
    required this.speed,
  });
}
