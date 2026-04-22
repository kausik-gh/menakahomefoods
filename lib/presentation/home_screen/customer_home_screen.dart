import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/menu_pricing.dart';
import '../../providers/customer_profile_notifier.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../core/app_localizations.dart';
import '../customer_main/customer_main_screen.dart';
import '../subscription/subscription_wizard_sheet.dart';

// ─── Dish Data ────────────────────────────────────────────────────────────────

class HomeDish {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isVeg;
  final String imageUrl;
  final String semanticLabel;
  final String meal; // breakfast, lunch, dinner
  final bool isChefSpecial;
  final String tag;

  const HomeDish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isVeg,
    required this.imageUrl,
    required this.semanticLabel,
    required this.meal,
    this.isChefSpecial = false,
    this.tag = '',
  });
}

const List<HomeDish> _allDishes = [
  // Breakfast
  HomeDish(
    id: 'b1',
    name: 'Masala Dosa',
    description: 'Crispy dosa with spiced potato filling, sambar & chutneys',
    price: 89,
    isVeg: true,
    imageUrl:
        'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg',
    semanticLabel:
        'Crispy golden masala dosa with sambar and coconut chutney on banana leaf',
    meal: 'breakfast',
    isChefSpecial: true,
    tag: '⭐ Chef Pick',
  ),
  HomeDish(
    id: 'b2',
    name: 'Idli Sambar',
    description: 'Soft steamed idlis with piping hot sambar and chutneys',
    price: 69,
    isVeg: true,
    imageUrl:
        'https://images.pexels.com/photos/4331489/pexels-photo-4331489.jpeg',
    semanticLabel:
        'Soft white idlis arranged on plate with sambar and green chutney',
    meal: 'breakfast',
    tag: '🌿 Healthy',
  ),
  HomeDish(
    id: 'b3',
    name: 'Poha',
    description: 'Light flattened rice with mustard, curry leaves & peanuts',
    price: 59,
    isVeg: true,
    imageUrl:
        'https://images.pexels.com/photos/7625056/pexels-photo-7625056.jpeg',
    semanticLabel:
        'Yellow poha with peanuts, curry leaves and coriander garnish in bowl',
    meal: 'breakfast',
  ),
  HomeDish(
    id: 'b4',
    name: 'Filter Coffee',
    description: 'Authentic South Indian decoction coffee with frothy milk',
    price: 39,
    isVeg: true,
    imageUrl:
        'https://images.pexels.com/photos/312418/pexels-photo-312418.jpeg',
    semanticLabel:
        'Traditional South Indian filter coffee in steel tumbler with frothy top',
    meal: 'breakfast',
    tag: '☕ Fresh',
  ),
  // Lunch
  HomeDish(
    id: 'l1',
    name: "Amma's Dal Tadka",
    description: 'Slow-cooked yellow dal with ghee tadka & fresh coriander',
    price: 129,
    isVeg: true,
    imageUrl:
        'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg',
    semanticLabel:
        'Golden dal tadka with tempering of cumin and dried chillies in clay bowl',
    meal: 'lunch',
    isChefSpecial: true,
    tag: '🏆 Best Seller',
  ),
  HomeDish(
    id: 'l2',
    name: 'Veg Thali',
    description: 'Complete meal: 2 sabzi, dal, rice, roti, salad & dessert',
    price: 149,
    isVeg: true,
    imageUrl:
        'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg',
    semanticLabel:
        'Full vegetarian thali with multiple bowls of curry, rice, roti and papad',
    meal: 'lunch',
    isChefSpecial: true,
    tag: '💰 Value',
  ),
  HomeDish(
    id: 'l3',
    name: 'Paneer Butter Masala',
    description: 'Creamy tomato-based gravy with soft paneer cubes',
    price: 169,
    isVeg: true,
    imageUrl:
        'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
    semanticLabel:
        'Creamy orange paneer butter masala with cottage cheese cubes in bowl',
    meal: 'lunch',
  ),
  HomeDish(
    id: 'l4',
    name: 'Chicken Curry',
    description: 'Home-style chicken curry with aromatic spices & gravy',
    price: 189,
    isVeg: false,
    imageUrl:
        'https://images.pexels.com/photos/2338407/pexels-photo-2338407.jpeg',
    semanticLabel:
        'Rich brown chicken curry with whole spices in traditional serving bowl',
    meal: 'lunch',
    tag: '🔥 Spicy',
  ),
  // Dinner
  HomeDish(
    id: 'd1',
    name: 'Chicken Biryani',
    description: 'Fragrant basmati rice layered with spiced chicken & saffron',
    price: 199,
    isVeg: false,
    imageUrl:
        'https://images.pexels.com/photos/1624487/pexels-photo-1624487.jpeg',
    semanticLabel:
        'Fragrant chicken biryani in clay pot with saffron rice and whole spices',
    meal: 'dinner',
    isChefSpecial: true,
    tag: '🔥 Hot',
  ),
  HomeDish(
    id: 'd2',
    name: 'Mutton Rogan Josh',
    description: 'Slow-cooked Kashmiri mutton in aromatic red gravy',
    price: 249,
    isVeg: false,
    imageUrl:
        'https://images.pexels.com/photos/2338407/pexels-photo-2338407.jpeg',
    semanticLabel:
        'Rich red mutton rogan josh with whole spices in copper serving bowl',
    meal: 'dinner',
    isChefSpecial: true,
    tag: '👨‍🍳 Special',
  ),
  HomeDish(
    id: 'd3',
    name: 'Dal Makhani',
    description: 'Creamy black lentils slow-cooked overnight with butter',
    price: 149,
    isVeg: true,
    imageUrl:
        'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg',
    semanticLabel:
        'Creamy dark dal makhani with butter swirl and coriander in black bowl',
    meal: 'dinner',
  ),
  HomeDish(
    id: 'd4',
    name: 'Gulab Jamun',
    description: 'Soft milk-solid dumplings soaked in rose-flavored syrup',
    price: 59,
    isVeg: true,
    imageUrl:
        'https://images.pexels.com/photos/1099680/pexels-photo-1099680.jpeg',
    semanticLabel:
        'Soft golden-brown gulab jamun soaked in rose sugar syrup in white bowl',
    meal: 'dinner',
    tag: '🍯 Sweet',
  ),
];

// ─── Home Screen ──────────────────────────────────────────────────────────────

class CustomerHomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const CustomerHomeScreen({super.key, required this.onNavigate});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with SingleTickerProviderStateMixin {
  String _selectedMeal = 'breakfast';
  late TabController _mealTabController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerProfileNotifier>().loadFromSupabase();
      }
    });
    _mealTabController = TabController(length: 3, vsync: this);
    _mealTabController.addListener(() {
      if (!_mealTabController.indexIsChanging) {
        setState(() {
          _selectedMeal = [
            'breakfast',
            'lunch',
            'dinner',
          ][_mealTabController.index];
        });
      }
    });
    CartState.instance.addListener(_onCartChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) setState(() => _scrollOffset = _scrollController.offset);
  }

  @override
  void dispose() {
    _mealTabController.dispose();
    _scrollController.dispose();
    CartState.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  String _getGreeting() {
    final loc = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (hour < 12) return loc.t('good_morning');
    if (hour < 17) return loc.t('good_afternoon');
    return loc.t('good_evening');
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🍳';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  List<HomeDish> get _mealDishes =>
      _allDishes.where((d) => d.meal == _selectedMeal).toList();

  List<HomeDish> get _chefSpecials =>
      _allDishes.where((d) => d.isChefSpecial).toList();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildAnimatedHeader(loc)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _OfferBannerCarousel()),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildSubscriptionBanner(loc)),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                loc.t('chefs_special'),
                Icons.star_rounded,
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildChefSpecials()),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                loc.t('order_now'),
                Icons.restaurant_rounded,
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildMealTabs(loc)),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _DishListCard(
                    dish: _mealDishes[index],
                    onAdd: () {
                      CartState.instance.addItem(
                        CartDish(
                          id: _mealDishes[index].id,
                          name: _mealDishes[index].name,
                          price: dishPrice(_mealDishes[index].isVeg),
                          isVeg: _mealDishes[index].isVeg,
                          imageUrl: _mealDishes[index].imageUrl,
                          semanticLabel: _mealDishes[index].semanticLabel,
                          meal: _mealDishes[index].meal,
                          quantity: 1,
                        ),
                      );
                      _showAddedToast(_mealDishes[index].name, loc);
                    },
                    onRemove: () =>
                        CartState.instance.removeItem(_mealDishes[index].id),
                    quantity:
                        CartState
                            .instance
                            .items[_mealDishes[index].id]
                            ?.quantity ??
                        0,
                  ),
                  childCount: _mealDishes.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddedToast(String name, AppLocalizations loc) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$name ${loc.t('added_to_cart')}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                widget.onNavigate(1);
              },
              child: Text(
                loc.t('view'),
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAnimatedHeader(AppLocalizations loc) {
    final compressed = _scrollOffset > 40;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF6),
        gradient: LinearGradient(
          colors: [const Color(0xFFE8F5EC), const Color(0xFFF5FBF6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        compressed ? 12 : 20,
        20,
        compressed ? 10 : 16,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: compressed ? 36 : 42,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/menaka_logo.svg',
                      height: compressed ? 36 : 42,
                      fit: BoxFit.contain,
                      semanticsLabel: 'Menaka Home Foods logo',
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Menaka',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: compressed ? 18 : 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Right: Cart icon with badge
              GestureDetector(
                onTap: () {
                  context.push('/cart');
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    if (CartState.instance.totalCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              '${CartState.instance.totalCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Thin divider
          const SizedBox(height: 8),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFC8E6C9),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Keep personalized greeting visible when header is collapsed on scroll.
          if (compressed) ...[
            const SizedBox(height: 8),
            Consumer<CustomerProfileNotifier>(
              builder: (context, profile, _) {
                final raw = profile.customer?['name'] as String?;
                final line = raw != null && raw.trim().isNotEmpty
                    ? 'Hi ${raw.trim().split(' ').first}! 👋'
                    : '${_getGreeting()} ${_getGreetingEmoji()}';
                return Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
            ),
          ],
          if (!compressed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Consumer<CustomerProfileNotifier>(
                  builder: (context, profile, _) {
                    final raw = profile.customer?['name'] as String?;
                    final line = raw != null && raw.trim().isNotEmpty
                        ? 'Hi ${raw.trim().split(' ').first}! 👋'
                        : '${_getGreeting()} ${_getGreetingEmoji()}';
                    return Text(
                      line,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  loc.t('what_to_eat'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChefSpecials() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chefSpecials.length,
        itemBuilder: (context, index) {
          final dish = _chefSpecials[index];
          final qty = CartState.instance.items[dish.id]?.quantity ?? 0;
          return _ChefSpecialCard(
            dish: dish,
            quantity: qty,
            onAdd: () {
              CartState.instance.addItem(
                CartDish(
                  id: dish.id,
                  name: dish.name,
                  price: dishPrice(dish.isVeg),
                  isVeg: dish.isVeg,
                  imageUrl: dish.imageUrl,
                  semanticLabel: dish.semanticLabel,
                  meal: dish.meal,
                  quantity: 1,
                ),
              );
            },
            onRemove: () => CartState.instance.removeItem(dish.id),
          );
        },
      ),
    );
  }

  Widget _buildMealTabs(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _mealTabController,
          indicator: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: '🌅 ${loc.t('breakfast')}'),
            Tab(text: '🍛 ${loc.t('lunch')}'),
            Tab(text: '🌙 ${loc.t('dinner')}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionBanner(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => showSubscriptionWizard(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF2D2D2D), Color(0xFF4A3728)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D2D2D).withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withAlpha(30),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent.withAlpha(25),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(60),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🔁 SUBSCRIPTION',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accent,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.t('subscribe_cta'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.t('subscribe_subtext'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white.withAlpha(180),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: AppTheme.buttonShadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.t('start_subscription'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      children: [
                        Text('🍛', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 4),
                        Text('🌅', style: TextStyle(fontSize: 24)),
                        SizedBox(height: 4),
                        Text('🌙', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Offer Banner Carousel ────────────────────────────────────────────────────

class _OfferBannerCarousel extends StatefulWidget {
  const _OfferBannerCarousel();

  @override
  State<_OfferBannerCarousel> createState() => _OfferBannerCarouselState();
}

class _OfferBannerCarouselState extends State<_OfferBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<_BannerItem> _banners = [
    _BannerItem(
      imageUrl:
          'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
      tag: '🎉 Limited Time',
      title: '50% OFF on\nFirst Order',
      subtitle: 'Use code: MENAKA50',
      gradientStart: const Color(0xFF2A5E32),
      gradientEnd: const Color(0xFF3A7D44),
      semanticLabel:
          'Colorful healthy meal bowl with fresh vegetables and grains',
    ),
    _BannerItem(
      imageUrl:
          'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg',
      tag: '🍛 Chef\'s Special',
      title: "Amma's Thali\nis Back!",
      subtitle: 'Full meal for just ₹149',
      gradientStart: const Color(0xFF5C4A1E),
      gradientEnd: const Color(0xFF8B7355),
      semanticLabel:
          'Traditional Indian thali with multiple bowls of curry and rice',
    ),
    _BannerItem(
      imageUrl:
          'https://images.pexels.com/photos/1640772/pexels-photo-1640772.jpeg',
      tag: '⚡ Flash Deal',
      title: 'Free Delivery\nAll Weekend',
      subtitle: 'No minimum order',
      gradientStart: const Color(0xFF1E4526),
      gradientEnd: const Color(0xFF3A7D44),
      semanticLabel:
          'Fresh green salad bowl with colorful vegetables on white background',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (p) => setState(() => _currentPage = p),
            itemCount: _banners.length,
            itemBuilder: (context, index) =>
                _BannerCard(banner: _banners[index]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? AppTheme.primary
                    : AppTheme.primary.withAlpha(64),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerItem {
  final String imageUrl, tag, title, subtitle, semanticLabel;
  final Color gradientStart, gradientEnd;
  const _BannerItem({
    required this.imageUrl,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.semanticLabel,
  });
}

class _BannerCard extends StatelessWidget {
  final _BannerItem banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomImageWidget(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
                semanticLabel: banner.semanticLabel,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      banner.gradientStart.withAlpha(224),
                      banner.gradientEnd.withAlpha(102),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 16,
                bottom: 16,
                right: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(64),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        banner.tag,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banner.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        banner.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: banner.gradientStart,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chef Special Card ────────────────────────────────────────────────────────

class _ChefSpecialCard extends StatelessWidget {
  final HomeDish dish;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ChefSpecialCard({
    required this.dish,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: CustomImageWidget(
                    imageUrl: dish.imageUrl,
                    fit: BoxFit.cover,
                    semanticLabel: dish.semanticLabel,
                  ),
                ),
                if (dish.tag.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dish.tag,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: dish.isVeg
                            ? const Color(0xFF4A7C59)
                            : const Color(0xFFD94F4F),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dish.isVeg
                              ? const Color(0xFF4A7C59)
                              : const Color(0xFFD94F4F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${dishPrice(dish.isVeg).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: dish.isVeg
                            ? const Color(0xFF4A7C59)
                            : const Color(0xFFD94F4F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    quantity == 0
                        ? GestureDetector(
                            onTap: onAdd,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              GestureDetector(
                                onTap: onRemove,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    color: AppTheme.primary,
                                    size: 14,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 24,
                                child: Center(
                                  child: Text(
                                    '$quantity',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: onAdd,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dish List Card ───────────────────────────────────────────────────────────

class _DishListCard extends StatelessWidget {
  final HomeDish dish;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _DishListCard({
    required this.dish,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: SizedBox(
              width: 100,
              height: 100,
              child: CustomImageWidget(
                imageUrl: dish.imageUrl,
                fit: BoxFit.cover,
                semanticLabel: dish.semanticLabel,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: dish.isVeg
                                ? const Color(0xFF4A7C59)
                                : const Color(0xFFD94F4F),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dish.isVeg
                                  ? const Color(0xFF4A7C59)
                                  : const Color(0xFFD94F4F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dish.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dish.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${dishPrice(dish.isVeg).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: dish.isVeg
                              ? const Color(0xFF4A7C59)
                              : const Color(0xFFD94F4F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      quantity == 0
                          ? GestureDetector(
                              onTap: onAdd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: AppTheme.buttonShadow,
                                ),
                                child: Text(
                                  'ADD',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                GestureDetector(
                                  onTap: onRemove,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      color: AppTheme.primary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Center(
                                    child: Text(
                                      '$quantity',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: onAdd,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
