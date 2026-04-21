import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/menu_pricing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../customer_main/customer_main_screen.dart';

class MenuScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const MenuScreen({super.key, required this.onNavigate});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

  // All menu dishes with availability toggle
  List<_MenuDish> _dishes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedCategory = _categories[_tabController.index]);
      }
    });
    _dishes = _buildDishes();
    CartState.instance.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    CartState.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  List<_MenuDish> _buildDishes() {
    return [
      _MenuDish(
        id: 'b1',
        name: 'Masala Dosa',
        description:
            'Crispy dosa with spiced potato filling, sambar & chutneys',
        price: 89,
        isVeg: true,
        category: 'Breakfast',
        imageUrl:
            'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg',
        semanticLabel:
            'Crispy golden masala dosa with sambar and coconut chutney',
        meal: 'breakfast',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'b2',
        name: 'Idli Sambar',
        description: 'Soft steamed idlis with piping hot sambar and chutneys',
        price: 69,
        isVeg: true,
        category: 'Breakfast',
        imageUrl:
            'https://images.pexels.com/photos/4331489/pexels-photo-4331489.jpeg',
        semanticLabel: 'Soft white idlis with sambar and green chutney',
        meal: 'breakfast',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'b3',
        name: 'Poha',
        description:
            'Light flattened rice with mustard, curry leaves & peanuts',
        price: 59,
        isVeg: true,
        category: 'Breakfast',
        imageUrl:
            'https://images.pexels.com/photos/7625056/pexels-photo-7625056.jpeg',
        semanticLabel: 'Yellow poha with peanuts and curry leaves in bowl',
        meal: 'breakfast',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'b4',
        name: 'Filter Coffee',
        description: 'Authentic South Indian decoction coffee with frothy milk',
        price: 39,
        isVeg: true,
        category: 'Breakfast',
        imageUrl:
            'https://images.pexels.com/photos/312418/pexels-photo-312418.jpeg',
        semanticLabel:
            'Traditional South Indian filter coffee in steel tumbler',
        meal: 'breakfast',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'l1',
        name: "Amma's Dal Tadka",
        description: 'Slow-cooked yellow dal with ghee tadka & fresh coriander',
        price: 129,
        isVeg: true,
        category: 'Lunch',
        imageUrl:
            'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg',
        semanticLabel: 'Golden dal tadka with tempering in clay bowl',
        meal: 'lunch',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'l2',
        name: 'Veg Thali',
        description: 'Complete meal: 2 sabzi, dal, rice, roti, salad & dessert',
        price: 149,
        isVeg: true,
        category: 'Lunch',
        imageUrl:
            'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg',
        semanticLabel: 'Full vegetarian thali with multiple bowls',
        meal: 'lunch',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'l3',
        name: 'Paneer Butter Masala',
        description: 'Creamy tomato-based gravy with soft paneer cubes',
        price: 169,
        isVeg: true,
        category: 'Lunch',
        imageUrl:
            'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
        semanticLabel: 'Creamy orange paneer butter masala in bowl',
        meal: 'lunch',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'l4',
        name: 'Chicken Curry',
        description: 'Home-style chicken curry with aromatic spices & gravy',
        price: 189,
        isVeg: false,
        category: 'Lunch',
        imageUrl:
            'https://images.pexels.com/photos/2338407/pexels-photo-2338407.jpeg',
        semanticLabel: 'Rich brown chicken curry in traditional serving bowl',
        meal: 'lunch',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'l5',
        name: 'Mutton Curry',
        description: 'Slow-cooked mutton in rich onion-tomato masala',
        price: 229,
        isVeg: false,
        category: 'Lunch',
        imageUrl:
            'https://images.pexels.com/photos/2338407/pexels-photo-2338407.jpeg',
        semanticLabel: 'Rich dark mutton curry with whole spices',
        meal: 'lunch',
        isAvailable: false,
      ),
      _MenuDish(
        id: 'd1',
        name: 'Chicken Biryani',
        description:
            'Fragrant basmati rice layered with spiced chicken & saffron',
        price: 199,
        isVeg: false,
        category: 'Dinner',
        imageUrl:
            'https://images.pexels.com/photos/1624487/pexels-photo-1624487.jpeg',
        semanticLabel: 'Fragrant chicken biryani in clay pot with saffron rice',
        meal: 'dinner',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'd2',
        name: 'Mutton Rogan Josh',
        description: 'Slow-cooked Kashmiri mutton in aromatic red gravy',
        price: 249,
        isVeg: false,
        category: 'Dinner',
        imageUrl:
            'https://images.pexels.com/photos/2338407/pexels-photo-2338407.jpeg',
        semanticLabel: 'Rich red mutton rogan josh in copper bowl',
        meal: 'dinner',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'd3',
        name: 'Dal Makhani',
        description: 'Creamy black lentils slow-cooked overnight with butter',
        price: 149,
        isVeg: true,
        category: 'Dinner',
        imageUrl:
            'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg',
        semanticLabel: 'Creamy dark dal makhani with butter swirl',
        meal: 'dinner',
        isAvailable: true,
      ),
      _MenuDish(
        id: 'd4',
        name: 'Gulab Jamun',
        description: 'Soft milk-solid dumplings soaked in rose-flavored syrup',
        price: 59,
        isVeg: true,
        category: 'Dinner',
        imageUrl:
            'https://images.pexels.com/photos/1099680/pexels-photo-1099680.jpeg',
        semanticLabel: 'Soft golden-brown gulab jamun in rose sugar syrup',
        meal: 'dinner',
        isAvailable: true,
      ),
      _MenuDish(
        id: 's1',
        name: 'Samosa (2 pcs)',
        description: 'Crispy fried pastry filled with spiced potato and peas',
        price: 49,
        isVeg: true,
        category: 'Snacks',
        imageUrl:
            'https://images.pexels.com/photos/4331489/pexels-photo-4331489.jpeg',
        semanticLabel: 'Crispy golden samosas with green chutney on plate',
        meal: 'snacks',
        isAvailable: true,
      ),
      _MenuDish(
        id: 's2',
        name: 'Pakoda Platter',
        description:
            'Assorted vegetable fritters with mint and tamarind chutney',
        price: 79,
        isVeg: true,
        category: 'Snacks',
        imageUrl:
            'https://images.pexels.com/photos/7625056/pexels-photo-7625056.jpeg',
        semanticLabel: 'Assorted vegetable pakodas with chutneys on plate',
        meal: 'snacks',
        isAvailable: true,
      ),
    ];
  }

  List<_MenuDish> get _filteredDishes {
    return _dishes.where((d) {
      final matchesCategory =
          _selectedCategory == 'All' || d.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _toggleAvailability(String id) {
    setState(() {
      final idx = _dishes.indexWhere((d) => d.id == id);
      if (idx != -1) {
        _dishes[idx] = _dishes[idx].copyWith(
          isAvailable: !_dishes[idx].isAvailable,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 8),
            _buildCategoryTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredDishes.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredDishes.length,
                      itemBuilder: (context, index) {
                        final dish = _filteredDishes[index];
                        final qty =
                            CartState.instance.items[dish.id]?.quantity ?? 0;
                        return _MenuDishCard(
                          dish: dish,
                          quantity: qty,
                          onAdd: dish.isAvailable
                              ? () {
                                  HapticFeedback.lightImpact();
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
                                }
                              : null,
                          onRemove: () =>
                              CartState.instance.removeItem(dish.id),
                          onToggleAvailability: () =>
                              _toggleAvailability(dish.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Menu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Fresh, home-cooked daily',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/cart'),
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
                  child: Icon(
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
                        color: AppTheme.error,
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search dishes...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat);
              _tabController.animateTo(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? AppTheme.buttonShadow
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: Text(
                cat,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            'No dishes found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            'Try a different search or category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDish {
  final String id, name, description, category, imageUrl, semanticLabel, meal;
  final double price;
  final bool isVeg, isAvailable;

  const _MenuDish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isVeg,
    required this.category,
    required this.imageUrl,
    required this.semanticLabel,
    required this.meal,
    required this.isAvailable,
  });

  _MenuDish copyWith({bool? isAvailable}) => _MenuDish(
    id: id,
    name: name,
    description: description,
    price: price,
    isVeg: isVeg,
    category: category,
    imageUrl: imageUrl,
    semanticLabel: semanticLabel,
    meal: meal,
    isAvailable: isAvailable ?? this.isAvailable,
  );
}

class _MenuDishCard extends StatelessWidget {
  final _MenuDish dish;
  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback onRemove;
  final VoidCallback onToggleAvailability;

  const _MenuDishCard({
    required this.dish,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: dish.isAvailable ? 1.0 : 0.6,
      child: Container(
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
              child: Stack(
                children: [
                  SizedBox(
                    width: 100,
                    height: 110,
                    child: CustomImageWidget(
                      imageUrl: dish.imageUrl,
                      fit: BoxFit.cover,
                      semanticLabel: dish.semanticLabel,
                    ),
                  ),
                  if (!dish.isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withAlpha(100),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Unavailable',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
                        GestureDetector(
                          onTap: onToggleAvailability,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: dish.isAvailable
                                  ? AppTheme.successLight
                                  : AppTheme.errorLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dish.isAvailable ? 'Available' : 'Sold Out',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: dish.isAvailable
                                    ? AppTheme.success
                                    : AppTheme.error,
                              ),
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
                        if (dish.isAvailable)
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
      ),
    );
  }
}
