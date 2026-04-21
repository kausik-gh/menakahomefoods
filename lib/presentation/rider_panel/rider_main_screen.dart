import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/customer_profile_notifier.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import './rider_completed_screen.dart';
import './rider_home_screen.dart';
import './rider_profile_screen.dart';

class RiderMainScreen extends StatefulWidget {
  const RiderMainScreen({super.key});

  @override
  State<RiderMainScreen> createState() => _RiderMainScreenState();
}

class _RiderMainScreenState extends State<RiderMainScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _riderName = 'Rider';
  String _riderPhone = '';
  String _riderId = '';
  bool _initialized = false;

  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initRider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _riderPhone = args['phone'] as String? ?? '';
      }
    }
  }

  Future<void> _initRider() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    // Fetch rider info from DB (match registered email)
    try {
      final res = await SupabaseService.instance.client
          .from('riders')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _riderName = res['name'] as String? ?? 'Rider';
          _riderId = res['id'] as String? ?? '';
          _riderPhone = res['phone'] as String? ?? _riderPhone;
        });

        // Set rider online
        await SupabaseService.instance.client
            .from('riders')
            .update({'status': 'active'})
            .eq('id', _riderId);

        // Start location broadcasting
        _startLocationBroadcast();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _riderName = 'Rider';
          _riderId = '';
        });
      }
    }
  }

  void _startLocationBroadcast() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _broadcastLocation();
    });
    // Broadcast immediately
    _broadcastLocation();
  }

  Future<void> _broadcastLocation() async {
    if (_riderId.isEmpty) return;
    try {
      // Use a simulated location since geolocator requires native setup
      // In production, replace with actual GPS coordinates
      final now = DateTime.now().toIso8601String();
      await SupabaseService.instance.client
          .from('riders')
          .update({'location_updated_at': now, 'status': 'active'})
          .eq('id', _riderId);
    } catch (e) {
      // silent
    }
  }

  Future<void> _logout() async {
    _locationTimer?.cancel();
    try {
      if (_riderId.isNotEmpty) {
        await SupabaseService.instance.client
            .from('riders')
            .update({'status': 'inactive', 'lat': null, 'lng': null})
            .eq('id', _riderId);
      }
    } catch (e) {
      // silent
    }
    if (mounted) {
      HapticFeedback.mediumImpact();
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        context.read<CustomerProfileNotifier>().clear();
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      RiderHomeScreen(riderName: _riderName, riderId: _riderId),
      RiderCompletedScreen(riderId: _riderId),
      RiderProfileScreen(
        riderName: _riderName,
        riderPhone: _riderPhone,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A7C59).withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TabItem(
                icon: Icons.home_rounded,
                label: 'Active',
                isActive: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _TabItem(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                isActive: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _TabItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF4A7C59);
    const inactiveColor = Color(0xFFAAAAAA);
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withAlpha(20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
