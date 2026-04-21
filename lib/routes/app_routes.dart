import 'package:flutter/material.dart';
import '../presentation/cart_screen/cart_screen.dart';
import '../presentation/checkout_screen/checkout_screen.dart';
import '../presentation/order_tracking_screen/order_tracking_screen.dart';
import '../presentation/delivery_dashboard_screen/delivery_dashboard_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_screen.dart';
import '../presentation/role_selection_screen/role_selection_screen.dart';
import '../presentation/home_screen/customer_home_screen.dart';

void _noopTab(int _) {}

class AppRoutes {
  static const String initial = '/';
  static const String roleSelectionScreen = '/role-selection-screen';
  static const String loginScreen = '/login-screen';
  static const String homeScreen = '/home-screen';
  static const String customerMainScreen = '/customer-main';
  static const String cartScreen = '/cart-screen';
  static const String checkoutScreen = '/checkout-screen';
  static const String orderTrackingScreen = '/order-tracking-screen';
  static const String deliveryDashboardScreen = '/delivery-dashboard-screen';
  static const String adminDashboardScreen = '/admin-dashboard-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const RoleSelectionScreen(),
    roleSelectionScreen: (context) => const RoleSelectionScreen(),
    loginScreen: (context) => const LoginScreen(),
    homeScreen: (context) => CustomerHomeScreen(onNavigate: _noopTab),
    customerMainScreen: (context) => CustomerHomeScreen(onNavigate: _noopTab),
    cartScreen: (context) => const CartScreen(),
    checkoutScreen: (context) => const CheckoutScreen(),
    orderTrackingScreen: (context) => const OrderTrackingScreen(),
    deliveryDashboardScreen: (context) => const DeliveryDashboardScreen(),
    adminDashboardScreen: (context) => const AdminDashboardScreen(),
  };
}
