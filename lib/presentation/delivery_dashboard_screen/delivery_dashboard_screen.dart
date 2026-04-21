import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

enum OrderStatus { assigned, pickedUp, onWay, delivered }

class DeliveryOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String address;
  final String landmark;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentMode;
  OrderStatus status;

  DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.landmark,
    required this.items,
    required this.totalAmount,
    required this.paymentMode,
    this.status = OrderStatus.assigned,
  });
}

class OrderItem {
  final String name;
  final int qty;
  final double price;

  OrderItem({required this.name, required this.qty, required this.price});
}

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen>
    with TickerProviderStateMixin {
  List<DeliveryOrder> _orders = [];
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  int _selectedTab = 0; // 0=Upcoming, 1=Ongoing, 2=Completed

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );

    _orders = [
      DeliveryOrder(
        id: 'ORD-1042',
        customerName: 'Priya Sharma',
        customerPhone: '+91 98765 43210',
        address: '14B, Lotus Apartments, MG Road, Bengaluru – 560001',
        landmark: 'Near HDFC Bank ATM',
        items: [
          OrderItem(name: 'Chicken Biryani', qty: 2, price: 280),
          OrderItem(name: 'Raita', qty: 1, price: 40),
          OrderItem(name: 'Gulab Jamun', qty: 2, price: 60),
        ],
        totalAmount: 660,
        paymentMode: 'Paid Online',
        status: OrderStatus.assigned,
      ),
      DeliveryOrder(
        id: 'ORD-1043',
        customerName: 'Arjun Mehta',
        customerPhone: '+91 87654 32109',
        address: '7, Green Park Colony, Indiranagar, Bengaluru – 560038',
        landmark: 'Opp. Indiranagar Metro Station',
        items: [
          OrderItem(name: 'Paneer Butter Masala', qty: 1, price: 220),
          OrderItem(name: 'Butter Naan', qty: 3, price: 90),
          OrderItem(name: 'Mango Lassi', qty: 2, price: 100),
        ],
        totalAmount: 410,
        paymentMode: 'Cash on Delivery',
        status: OrderStatus.pickedUp,
      ),
      DeliveryOrder(
        id: 'ORD-1044',
        customerName: 'Sneha Reddy',
        customerPhone: '+91 76543 21098',
        address: '22, Sunrise Villa, Koramangala 5th Block, Bengaluru – 560095',
        landmark: 'Behind Forum Mall',
        items: [
          OrderItem(name: 'Masala Dosa', qty: 2, price: 120),
          OrderItem(name: 'Filter Coffee', qty: 2, price: 60),
          OrderItem(name: 'Vada', qty: 4, price: 80),
        ],
        totalAmount: 260,
        paymentMode: 'Paid Online',
        status: OrderStatus.delivered,
      ),
    ];
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  List<DeliveryOrder> get _filteredOrders {
    switch (_selectedTab) {
      case 0:
        return _orders.where((o) => o.status == OrderStatus.assigned).toList();
      case 1:
        return _orders
            .where(
              (o) =>
                  o.status == OrderStatus.pickedUp ||
                  o.status == OrderStatus.onWay,
            )
            .toList();
      case 2:
        return _orders.where((o) => o.status == OrderStatus.delivered).toList();
      default:
        return _orders;
    }
  }

  int get _deliveredCount =>
      _orders.where((o) => o.status == OrderStatus.delivered).length;
  int get _activeCount => _orders
      .where(
        (o) =>
            o.status == OrderStatus.pickedUp || o.status == OrderStatus.onWay,
      )
      .length;
  int get _upcomingCount =>
      _orders.where((o) => o.status == OrderStatus.assigned).length;

  void _updateStatus(DeliveryOrder order, OrderStatus newStatus) {
    setState(() {
      order.status = newStatus;
    });

    final label = newStatus == OrderStatus.pickedUp
        ? '📦 Order Picked Up!'
        : newStatus == OrderStatus.onWay
        ? '🚴 On the Way!'
        : '✅ Order Delivered!';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: newStatus == OrderStatus.delivered
            ? AppTheme.success
            : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsRow(),
            _buildTabBar(),
            Expanded(
              child: _filteredOrders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        return _DeliveryOrderCard(
                          order: _filteredOrders[index],
                          onStatusUpdate: _updateStatus,
                          animationDelay: Duration(milliseconds: 80 * index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rider Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Today's delivery orders",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                  const SizedBox(width: 5),
                  Text(
                    'Online',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          _StatChip(
            label: 'Upcoming',
            value: '$_upcomingCount',
            color: const Color(0xFF2563EB),
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Active',
            value: '$_activeCount',
            color: AppTheme.accent,
            icon: Icons.directions_bike_rounded,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Delivered',
            value: '$_deliveredCount',
            color: AppTheme.success,
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Upcoming', 'Ongoing', 'Completed'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back soon for new deliveries',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryOrderCard extends StatefulWidget {
  final DeliveryOrder order;
  final Function(DeliveryOrder, OrderStatus) onStatusUpdate;
  final Duration animationDelay;

  const _DeliveryOrderCard({
    required this.order,
    required this.onStatusUpdate,
    required this.animationDelay,
  });

  @override
  State<_DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends State<_DeliveryOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    Future.delayed(widget.animationDelay, () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.order.status) {
      case OrderStatus.assigned:
        return const Color(0xFF2563EB);
      case OrderStatus.pickedUp:
        return AppTheme.accent;
      case OrderStatus.onWay:
        return AppTheme.primary;
      case OrderStatus.delivered:
        return AppTheme.success;
    }
  }

  String get _statusLabel {
    switch (widget.order.status) {
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onWay:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: _statusColor.withAlpha(40), width: 1),
          ),
          child: Column(
            children: [
              // Header
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: _statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.order.customerName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.order.id,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Address
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.order.address,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            '📍 ${widget.order.landmark}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Expandable items
              if (_isExpanded) ...[
                const Divider(height: 1, color: Color(0xFFEFF7F1)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Items',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.name} × ${item.qty}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${(item.price * item.qty).toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 16, color: Color(0xFFEFF7F1)),
                      Row(
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${widget.order.totalAmount.toInt()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: widget.order.paymentMode == 'Paid Online'
                                  ? AppTheme.successLight
                                  : AppTheme.warningLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.order.paymentMode,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: widget.order.paymentMode == 'Paid Online'
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Action Buttons
              if (widget.order.status != OrderStatus.delivered) ...[
                const Divider(height: 1, color: Color(0xFFEFF7F1)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildActionButtons(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (widget.order.status) {
      case OrderStatus.assigned:
        return _ActionButton(
          label: '📦  Picked Up',
          color: const Color(0xFF2563EB),
          onTap: () =>
              widget.onStatusUpdate(widget.order, OrderStatus.pickedUp),
        );
      case OrderStatus.pickedUp:
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: '🚴  On the Way',
                color: AppTheme.accent,
                onTap: () =>
                    widget.onStatusUpdate(widget.order, OrderStatus.onWay),
              ),
            ),
          ],
        );
      case OrderStatus.onWay:
        return _ActionButton(
          label: '✅  Mark Delivered',
          color: AppTheme.success,
          onTap: () =>
              widget.onStatusUpdate(widget.order, OrderStatus.delivered),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
