import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/customer_profile_notifier.dart';
import '../../theme/app_theme.dart';
import './widgets/admin_analytics_tab.dart';
import './widgets/admin_menu_tab.dart';
import './widgets/admin_orders_tab.dart';
import './widgets/admin_riders_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  int _selectedTab = 0;

  final List<_TabMeta> _tabs = const [
    _TabMeta(label: 'Orders', icon: Icons.receipt_long_rounded),
    _TabMeta(label: 'Riders', icon: Icons.delivery_dining_rounded),
    _TabMeta(label: 'Menu', icon: Icons.restaurant_menu_rounded),
    _TabMeta(label: 'Analytics', icon: Icons.bar_chart_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(gradient: AppTheme.leafGradient),
      child: Row(
        children: [
          Image.asset(
            'assets/images/image-1776498594905.png',
            height: 36,
            fit: BoxFit.contain,
            semanticLabel: 'Menaka Home Foods logo',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Menaka Home Foods',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              context.read<CustomerProfileNotifier>().clear();
              context.go('/login');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Logout',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = _selectedTab == i;
          final tab = _tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return const AdminOrdersTab();
      case 1:
        return const AdminRidersTab();
      case 2:
        return const AdminMenuTab();
      case 3:
        return const AdminAnalyticsTab();
      default:
        return const AdminOrdersTab();
    }
  }
}

class _TabMeta {
  final String label;
  final IconData icon;
  const _TabMeta({required this.label, required this.icon});
}
