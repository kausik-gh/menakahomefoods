import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/supabase_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Breakfast', 'Lunch', 'Dinner'];
  List<_MenuDish> _dishes = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedCategory = _categories[_tabController.index]);
      }
    });
    _loadMenu();
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

  Future<void> _loadMenu() async {
    setState(() => _loading = true);
    final rows = await SupabaseService.instance.getMenuItems();
    final dishes = rows
        .map(_MenuDish.fromMap)
        .where(
          (dish) => const ['breakfast', 'lunch', 'dinner'].contains(dish.meal),
        )
        .toList();
    if (!mounted) return;
    setState(() {
      _dishes = dishes;
      _loading = false;
    });
  }

  List<_MenuDish> get _filteredDishes {
    return _dishes.where((dish) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          dish.meal == _selectedCategory.toLowerCase();
      final needle = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          needle.isEmpty ||
          dish.name.toLowerCase().contains(needle) ||
          dish.description.toLowerCase().contains(needle);
      return matchesCategory && matchesSearch;
    }).toList();
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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _filteredDishes.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadMenu,
                      color: AppTheme.primary,
                      child: ListView.builder(
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
                                        price: dish.price,
                                        isVeg: dish.isVeg,
                                        imageUrl: dish.imageUrl ?? '',
                                        semanticLabel: dish.semanticLabel,
                                        meal: dish.meal,
                                        quantity: 1,
                                      ),
                                    );
                                  }
                                : null,
                            onRemove: () =>
                                CartState.instance.removeItem(dish.id),
                          );
                        },
                      ),
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
          onChanged: (value) => setState(() => _searchQuery = value),
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
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category);
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
                category,
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
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isVeg;
  final String meal;
  final bool isAvailable;
  final String? imageUrl;
  final String semanticLabel;

  const _MenuDish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isVeg,
    required this.meal,
    required this.isAvailable,
    required this.imageUrl,
    required this.semanticLabel,
  });

  factory _MenuDish.fromMap(Map<String, dynamic> map) {
    final rawImageUrl = (map['image_url'] as String?)?.trim();
    final meal = ((map['meal_type'] as String?) ?? 'breakfast')
        .trim()
        .toLowerCase();
    final availableToday = map['available_today'] as bool?;
    final availableForOrder = map['available_for_order'] as bool?;

    return _MenuDish(
      id: map['id'] as String,
      name: ((map['name'] as String?) ?? '').trim(),
      description: ((map['description'] as String?) ?? '').trim(),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      isVeg: map['is_veg'] as bool? ?? true,
      meal: meal,
      isAvailable: (availableToday ?? true) && (availableForOrder ?? true),
      imageUrl: rawImageUrl == null || rawImageUrl.isEmpty ? null : rawImageUrl,
      semanticLabel: ((map['name'] as String?) ?? 'Menu item').trim(),
    );
  }
}

class _MenuDishCard extends StatelessWidget {
  final _MenuDish dish;
  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback onRemove;

  const _MenuDishCard({
    required this.dish,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
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
                    child: _DishImage(
                      imageUrl: dish.imageUrl,
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
                        Container(
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
                          '₹${dish.price.toStringAsFixed(0)}',
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

class _DishImage extends StatelessWidget {
  final String? imageUrl;
  final String semanticLabel;

  const _DishImage({required this.imageUrl, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(color: const Color(0xFFE1E5EA));
    }

    return CustomImageWidget(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      errorWidget: Container(color: const Color(0xFFE1E5EA)),
    );
  }
}
