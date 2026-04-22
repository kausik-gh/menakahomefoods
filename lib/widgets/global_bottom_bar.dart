import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/app_localizations.dart';
import '../providers/customer_profile_notifier.dart';

class GlobalBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onCustomerTabTap;

  const GlobalBottomBar({
    super.key,
    required this.currentIndex,
    this.onCustomerTabTap,
  });

  void _handleTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();

    switch (index) {
      case 0:
      case 1:
      case 2:
      case 3:
        if (onCustomerTabTap != null) {
          onCustomerTabTap!(index);
          return;
        }
        final route = switch (index) {
          0 => '/home',
          1 => '/menu',
          2 => '/track',
          _ => '/profile',
        };
        context.go(route);
        return;
      case 4:
        context.go('/admin');
        return;
      case 5:
        context.go('/rider');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final role = context.watch<CustomerProfileNotifier>().role;
    final items = <_BottomBarItem>[
      _BottomBarItem(
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: loc.t('home'),
      ),
      _BottomBarItem(
        index: 1,
        icon: Icons.restaurant_menu_outlined,
        activeIcon: Icons.restaurant_menu_rounded,
        label: loc.t('menu'),
      ),
      _BottomBarItem(
        index: 2,
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on_rounded,
        label: loc.t('track'),
      ),
      _BottomBarItem(
        index: 3,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: loc.t('profile'),
      ),
    ];
    if (role == 'admin') {
      items.add(
        const _BottomBarItem(
          index: 4,
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings_rounded,
          label: 'Admin',
        ),
      );
    }
    if (role == 'rider') {
      items.add(
        const _BottomBarItem(
          index: 5,
          icon: Icons.delivery_dining_outlined,
          activeIcon: Icons.delivery_dining_rounded,
          label: 'Rider',
        ),
      );
    }

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
            children: List.generate(items.length, (index) {
              final item = items[index];
              return _GlobalBottomBarTab(
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                isActive: currentIndex == item.index,
                onTap: () => _handleTap(context, item.index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _BottomBarItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _GlobalBottomBarTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _GlobalBottomBarTab({
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
