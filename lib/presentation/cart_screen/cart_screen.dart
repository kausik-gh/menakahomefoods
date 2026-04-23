import 'package:go_router/go_router.dart';

import '../../core/app_export.dart';
import '../customer_main/customer_main_screen.dart';
import './widgets/cart_checkout_button_widget.dart';
import './widgets/cart_empty_widget.dart';
import './widgets/cart_item_widget.dart';
import './widgets/cart_price_breakdown_widget.dart';

// TODO: Replace with Riverpod/Bloc for production

class CartItemModel {
  final String id;
  final String name;
  final double price;
  final bool isVeg;
  final String imageUrl;
  final String semanticLabel;
  final String customization;
  int quantity;

  CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isVeg,
    required this.imageUrl,
    required this.semanticLabel,
    required this.customization,
    required this.quantity,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      isVeg: map['isVeg'] as bool,
      imageUrl: map['imageUrl'] as String,
      semanticLabel: map['semanticLabel'] as String,
      customization: map['customization'] as String,
      quantity: map['quantity'] as int,
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isCheckingOut = false;
  String _appliedCoupon = 'MENAKA50';

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

  List<CartItemModel> get _cartItems {
    return CartState.instance.items.values.map((d) {
      return CartItemModel(
        id: d.id,
        name: d.name,
        price: d.price,
        isVeg: d.isVeg,
        imageUrl: d.imageUrl,
        semanticLabel: d.semanticLabel,
        customization: '',
        quantity: d.quantity,
      );
    }).toList();
  }

  double get _subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  double get _deliveryFee => _subtotal >= 300 ? 0 : 29.0;

  double get _discount =>
      _appliedCoupon.isNotEmpty ? (_subtotal * 0.1).clamp(0, 60) : 0;

  double get _gst => (_subtotal - _discount) * 0.05;

  double get _total => _subtotal - _discount + _deliveryFee + _gst;

  int get _totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void _updateQuantity(String id, int delta) {
    if (delta > 0) {
      final d = CartState.instance.items[id];
      if (d != null) CartState.instance.addItem(d);
    } else {
      CartState.instance.removeItem(id);
    }
    setState(() {});
  }

  void _removeItem(String id) {
    CartState.instance.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Item removed from cart',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        backgroundColor: AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppTheme.accent,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    setState(() => _isCheckingOut = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isCheckingOut = false);
      context.push(
        '/checkout',
        extra: {
          'items': _cartItems
              .map(
                (item) => {
                  'name': item.name,
                  'qty': item.quantity,
                  'price': item.price,
                  'isVeg': item.isVeg,
                },
              )
              .toList(),
          'subtotal': _subtotal,
          'deliveryFee': _deliveryFee,
          'discount': _discount,
          'gst': _gst,
          'total': _total,
          'couponCode': _appliedCoupon,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isEmpty = _cartItems.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: false,
        child: isEmpty
            ? CartEmptyWidget(onBrowse: () => context.go('/home'))
            : isTablet
            ? _buildTabletLayout()
            : _buildPhoneLayout(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(76),
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
                        'My Cart',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$_totalItems ${_totalItems == 1 ? 'item' : 'items'} · ₹${_total.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withAlpha(217),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_appliedCoupon.isNotEmpty)
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
                          Icons.local_offer_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _appliedCoupon,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
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

  Widget _buildPhoneLayout() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            physics: const BouncingScrollPhysics(),
            children: [
              // Savings Banner
              if (_appliedCoupon.isNotEmpty) _buildSavingsBanner(),
              const SizedBox(height: 12),
              // Cart Items
              ..._cartItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CartItemWidget(
                    item: item,
                    onIncrease: () => _updateQuantity(item.id, 1),
                    onDecrease: () => _updateQuantity(item.id, -1),
                    onRemove: () => _removeItem(item.id),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Coupon Row
              _buildCouponRow(),
              const SizedBox(height: 16),
              // Price Breakdown
              CartPriceBreakdownWidget(
                subtotal: _subtotal,
                deliveryFee: _deliveryFee,
                discount: _discount,
                gst: _gst,
                total: _total,
                couponCode: _appliedCoupon,
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
        CartCheckoutButtonWidget(
          total: _total,
          isLoading: _isCheckingOut,
          onCheckout: _handleCheckout,
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              if (_appliedCoupon.isNotEmpty) _buildSavingsBanner(),
              const SizedBox(height: 12),
              ..._cartItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CartItemWidget(
                    item: item,
                    onIncrease: () => _updateQuantity(item.id, 1),
                    onDecrease: () => _updateQuantity(item.id, -1),
                    onRemove: () => _removeItem(item.id),
                  ),
                ),
              ),
              _buildCouponRow(),
            ],
          ),
        ),
        Container(
          width: 1,
          color: const Color(0xFFC8E6C9),
          margin: const EdgeInsets.symmetric(vertical: 16),
        ),
        SizedBox(
          width: 340,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CartPriceBreakdownWidget(
                subtotal: _subtotal,
                deliveryFee: _deliveryFee,
                discount: _discount,
                gst: _gst,
                total: _total,
                couponCode: _appliedCoupon,
              ),
              const SizedBox(height: 20),
              CartCheckoutButtonWidget(
                total: _total,
                isLoading: _isCheckingOut,
                onCheckout: _handleCheckout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_rounded,
            size: 16,
            color: AppTheme.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re saving ₹${_discount.toStringAsFixed(0)} with code $_appliedCoupon 🎉',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.success,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _appliedCoupon = ''),
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.discount_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appliedCoupon.isNotEmpty
                      ? 'Coupon Applied: $_appliedCoupon'
                      : 'Apply Coupon',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _appliedCoupon.isNotEmpty
                      ? 'Saving ₹${_discount.toStringAsFixed(0)} on this order'
                      : 'Get upto 10% off on your order',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _appliedCoupon.isNotEmpty
                        ? AppTheme.success
                        : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _appliedCoupon.isNotEmpty ? 'Remove' : 'Apply',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
