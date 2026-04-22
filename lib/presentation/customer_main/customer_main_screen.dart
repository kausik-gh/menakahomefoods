import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../core/menu_pricing.dart';
import '../../widgets/global_bottom_bar.dart';

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
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: shell,
      bottomNavigationBar: GlobalBottomBar(
        currentIndex: shell.currentIndex,
        onCustomerTabTap: _onTabTap,
      ),
    );
  }
}
