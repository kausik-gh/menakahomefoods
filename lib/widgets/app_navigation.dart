import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

class AppNavigationWidget extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final String role; // 'customer', 'delivery', 'admin'

  const AppNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    this.role = 'customer',
  });

  @override
  State<AppNavigationWidget> createState() => _AppNavigationWidgetState();
}

class _AppNavigationWidgetState extends State<AppNavigationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillController;

  List<_NavItem> get _items {
    // Customer-only navigation
    return [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Orders',
      ),
      _NavItem(
        icon: Icons.shopping_bag_outlined,
        activeIcon: Icons.shopping_bag_rounded,
        label: 'Cart',
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  void _handleTabTap(int index) {
    if (index == 0) {
      Navigator.pushNamed(context, AppRoutes.homeScreen);
      return;
    }
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.orderTrackingScreen);
      return;
    }
    if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.cartScreen);
      return;
    }
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppTheme.navShadow,
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final isActive = index == widget.currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => _handleTabTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isActive
                              ? _items[index].activeIcon
                              : _items[index].icon,
                          key: ValueKey(isActive),
                          size: 22,
                          color: isActive ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 2),
                        Text(
                          _items[index].label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({required this.icon, required this.activeIcon, required this.label});
}
