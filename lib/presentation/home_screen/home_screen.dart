import 'package:go_router/go_router.dart';

import '../../core/app_export.dart';
import '../../widgets/app_navigation.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/home_banner_widget.dart';
import './widgets/home_categories_widget.dart';
import './widgets/home_food_grid_widget.dart';
import './widgets/home_search_bar_widget.dart';
import './widgets/home_section_header_widget.dart';

// TODO: Replace with Riverpod/Bloc for production
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  int _cartItemCount = 2;
  String _selectedCategory = 'All';
  bool _isLoading = false;

  // TODO: Replace with Riverpod/Bloc for production
  final Map<String, int> _cartItems = {};

  void _onNavChanged(int index) {
    // TODO: Replace with Riverpod/Bloc for production
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.orderTrackingScreen);
      return;
    }
    setState(() => _currentNavIndex = index);
  }

  void _onAddToCart(String dishId) {
    // TODO: Replace with Riverpod/Bloc for production
    setState(() {
      _cartItems[dishId] = (_cartItems[dishId] ?? 0) + 1;
      _cartItemCount = _cartItems.values.fold(0, (a, b) => a + b);
    });
  }

  void _onRemoveFromCart(String dishId) {
    // TODO: Replace with Riverpod/Bloc for production
    setState(() {
      if ((_cartItems[dishId] ?? 0) > 0) {
        _cartItems[dishId] = _cartItems[dishId]! - 1;
        if (_cartItems[dishId] == 0) _cartItems.remove(dishId);
      }
      _cartItemCount = _cartItems.values.fold(0, (a, b) => a + b);
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeAppBarWidget(
              cartItemCount: _cartItemCount,
              onCartTap: () => context.push('/cart'),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                backgroundColor: Colors.white,
                displacement: 16,
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: HomeSearchBarWidget(onSearch: (query) {}),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    const SliverToBoxAdapter(child: HomeBannerWidget()),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(
                      child: HomeCategoriesWidget(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (cat) {
                          setState(() => _selectedCategory = cat);
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(
                      child: HomeSectionHeaderWidget(
                        title: "Chef's Specials",
                        subtitle: 'Made fresh today',
                        icon: Icons.star_rounded,
                        onViewAll: () {},
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        isTablet ? 24 : 90,
                      ),
                      sliver: HomeFoodGridWidget(
                        isLoading: _isLoading,
                        selectedCategory: _selectedCategory,
                        cartItems: _cartItems,
                        isTablet: isTablet,
                        onAddToCart: _onAddToCart,
                        onRemoveFromCart: _onRemoveFromCart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigationWidget(
        currentIndex: _currentNavIndex,
        onTabChanged: _onNavChanged,
      ),
    );
  }
}
