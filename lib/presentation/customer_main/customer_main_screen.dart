import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/app_localizations.dart';
import '../../core/menu_pricing.dart';

/// Cart state shared across tabs
class CartState {
  static final CartState _instance = CartState._();
  static CartState get instance => _instance;
  CartState._();

  final Map<String, CartDish> items = {};
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in _listeners) {
      cb();
    }
  }

  void addItem(CartDish dish) {
    if (items.containsKey(dish.id)) {
      items[dish.id]!.quantity++;
    } else {
      items[dish.id] = CartDish(
        id: dish.id,
        name: dish.name,
        price: dish.price,
        isVeg: dish.isVeg,
        imageUrl: dish.imageUrl,
        semanticLabel: dish.semanticLabel,
        meal: dish.meal,
        quantity: 1,
      );
    }
    _notify();
  }

  void removeItem(String id) {
    if (items.containsKey(id)) {
      if (items[id]!.quantity > 1) {
        items[id]!.quantity--;
      } else {
        items.remove(id);
      }
      _notify();
    }
  }

  void deleteItem(String id) {
    items.remove(id);
    _notify();
  }

  void clear() {
    items.clear();
    _notify();
  }

  int get totalCount => items.values.fold(0, (s, d) => s + d.quantity);
  double get subtotal => items.values.fold(
        0.0,
        (s, d) => s + getPrice(d.isVeg) * d.quantity,
      );
}

class CartDish {
  final String id;
  final String name;
  final double price;
  final bool isVeg;
  final String imageUrl;
  final String semanticLabel;
  final String meal;
  int quantity;

  CartDish({
    required this.id,
    required this.name,
    required this.price,
    required this.isVeg,
    required this.imageUrl,
    required this.semanticLabel,
    required this.meal,
    required this.quantity,
  });
}

class CustomerMainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const CustomerMainScreen({super.key, required this.navigationShell});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
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

  void _onTabTap(int index) {
    if (index == widget.navigationShell.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final shell = widget.navigationShell;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: shell,
      bottomNavigationBar: _buildBottomNav(loc, shell.currentIndex),
    );
  }

  Widget _buildBottomNav(AppLocalizations loc, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _TabItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: loc.t('home'),
                isActive: currentIndex == 0,
                onTap: () => _onTabTap(0),
              ),
              _TabItem(
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu_rounded,
                label: loc.t('menu'),
                isActive: currentIndex == 1,
                onTap: () => _onTabTap(1),
              ),
              _TabItem(
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on_rounded,
                label: loc.t('track'),
                isActive: currentIndex == 2,
                onTap: () => _onTabTap(2),
              ),
              _TabItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: loc.t('profile'),
                isActive: currentIndex == 3,
                onTap: () => _onTabTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable tab item with identical structure for all tabs
class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF4A7C59) : const Color(0xFFAAAAAA);
    return Expanded(
      flex: 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
