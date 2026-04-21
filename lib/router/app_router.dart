import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_screen.dart';
import '../presentation/cart_screen/cart_screen.dart';
import '../presentation/checkout_screen/checkout_screen.dart';
import '../presentation/customer_main/customer_main_screen.dart';
import '../presentation/rider_panel/rider_main_screen.dart';
import '../presentation/home_screen/customer_home_screen.dart';
import '../presentation/menu_screen/menu_screen.dart';
import '../presentation/order_success_screen/order_success_screen.dart';
import '../presentation/order_tracking_screen/order_tracking_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/auth_screen/auth_screen.dart';
import '../screens/splash_screen.dart';

/// Root navigator for full-screen routes (cart, checkout, etc.).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createAppRouter({required String initialLocation}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/landing', redirect: (context, state) => '/splash'),
      GoRoute(path: '/', redirect: (context, state) => '/splash'),
      GoRoute(path: '/login', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const AuthScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomerMainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) {
                  void goTab(int i) =>
                      StatefulNavigationShell.of(context).goBranch(i);
                  return CustomerHomeScreen(onNavigate: goTab);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/menu',
                builder: (context, state) {
                  void goTab(int i) =>
                      StatefulNavigationShell.of(context).goBranch(i);
                  return MenuScreen(onNavigate: goTab);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/track',
                builder: (context, state) => const OrderTrackingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/cart',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OrderSuccessScreen(),
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/rider',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RiderMainScreen(),
      ),
    ],
  );
}
