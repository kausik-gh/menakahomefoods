import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/menu_pricing.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/loading_skeleton_widget.dart';

class DishModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final int reviewCount;
  final String prepTime;
  final bool isVeg;
  final bool isChefSpecial;
  final bool isAvailable;
  final String imageUrl;
  final String semanticLabel;
  final String tag;
  final double? originalPrice;

  const DishModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.prepTime,
    required this.isVeg,
    this.isChefSpecial = false,
    this.isAvailable = true,
    required this.imageUrl,
    required this.semanticLabel,
    this.tag = '',
    this.originalPrice,
  });

  factory DishModel.fromMap(Map<String, dynamic> map) {
    return DishModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      rating: (map['rating'] as num).toDouble(),
      reviewCount: map['reviewCount'] as int,
      prepTime: map['prepTime'] as String,
      isVeg: map['isVeg'] as bool,
      isChefSpecial: map['isChefSpecial'] as bool? ?? false,
      isAvailable: map['isAvailable'] as bool? ?? true,
      imageUrl: map['imageUrl'] as String,
      semanticLabel: map['semanticLabel'] as String,
      tag: map['tag'] as String? ?? '',
      originalPrice: map['originalPrice'] != null
          ? (map['originalPrice'] as num).toDouble()
          : null,
    );
  }
}

final List<Map<String, dynamic>> _dishMaps = [
  {
    'id': 'd1',
    'name': 'Amma\'s Dal Tadka',
    'category': 'Meals',
    'price': 129.0,
    'rating': 4.8,
    'reviewCount': 342,
    'prepTime': '20 min',
    'isVeg': true,
    'isChefSpecial': true,
    'isAvailable': true,
    'imageUrl':
        'https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg',
    'semanticLabel':
        'Bowl of golden dal tadka with tempering of cumin, dried chillies and coriander garnish',
    'tag': 'Best Seller',
    'originalPrice': 159.0,
  },
  {
    'id': 'd2',
    'name': 'Chicken Biryani',
    'category': 'Specials',
    'price': 199.0,
    'rating': 4.9,
    'reviewCount': 521,
    'prepTime': '35 min',
    'isVeg': false,
    'isChefSpecial': true,
    'isAvailable': true,
    'imageUrl':
        'https://img.rocket.new/generatedImages/rocket_gen_img_1a1092190-1772819678104.png',
    'semanticLabel':
        'Fragrant chicken biryani served in clay pot with saffron rice and whole spices',
    'tag': '🔥 Hot',
    'originalPrice': null,
  },
  {
    'id': 'd3',
    'name': 'Masala Dosa',
    'category': 'Snacks',
    'price': 89.0,
    'rating': 4.7,
    'reviewCount': 289,
    'prepTime': '15 min',
    'isVeg': true,
    'isChefSpecial': false,
    'isAvailable': true,
    'imageUrl':
        'https://img.rocket.new/generatedImages/rocket_gen_img_1760c8867-1769240037094.png',
    'semanticLabel':
        'Crispy golden masala dosa served with sambar and three varieties of chutney',
    'tag': '',
    'originalPrice': null,
  },
  {
    'id': 'd4',
    'name': 'Veg Thali',
    'category': 'Thali',
    'price': 149.0,
    'rating': 4.6,
    'reviewCount': 198,
    'prepTime': '25 min',
    'isVeg': true,
    'isChefSpecial': true,
    'isAvailable': true,
    'imageUrl': 'https://images.unsplash.com/photo-1723388800779-5699cc142f18',
    'semanticLabel':
        'Full vegetarian thali with multiple small bowls of sabzi, dal, rice, roti and papad',
    'tag': 'Value Meal',
    'originalPrice': 199.0,
  },
  {
    'id': 'd5',
    'name': 'Gulab Jamun',
    'category': 'Desserts',
    'price': 59.0,
    'rating': 4.5,
    'reviewCount': 156,
    'prepTime': '10 min',
    'isVeg': true,
    'isChefSpecial': false,
    'isAvailable': true,
    'imageUrl':
        'https://img.rocket.new/generatedImages/rocket_gen_img_186d6a258-1773074194250.png',
    'semanticLabel':
        'Soft golden-brown gulab jamun soaked in rose-flavored sugar syrup in white bowl',
    'tag': '🍯 Sweet',
    'originalPrice': null,
  },
  {
    'id': 'd6',
    'name': 'Mutton Curry',
    'category': 'Specials',
    'price': 249.0,
    'rating': 4.7,
    'reviewCount': 203,
    'prepTime': '40 min',
    'isVeg': false,
    'isChefSpecial': true,
    'isAvailable': false,
    'imageUrl':
        'https://img.rocket.new/generatedImages/rocket_gen_img_1a45e064c-1773074195376.png',
    'semanticLabel':
        'Rich dark mutton curry with whole spices in a traditional copper serving bowl',
    'tag': 'Sold Out',
    'originalPrice': null,
  },
  {
    'id': 'd7',
    'name': 'Paneer Butter Masala',
    'category': 'Meals',
    'price': 169.0,
    'rating': 4.6,
    'reviewCount': 267,
    'prepTime': '20 min',
    'isVeg': true,
    'isChefSpecial': false,
    'isAvailable': true,
    'imageUrl': 'https://images.unsplash.com/photo-1708621010281-7815e86df602',
    'semanticLabel':
        'Creamy orange paneer butter masala with cubes of cottage cheese in tomato cream sauce',
    'tag': '',
    'originalPrice': null,
  },
  {
    'id': 'd8',
    'name': 'Filter Coffee',
    'category': 'Beverages',
    'price': 39.0,
    'rating': 4.9,
    'reviewCount': 445,
    'prepTime': '5 min',
    'isVeg': true,
    'isChefSpecial': false,
    'isAvailable': true,
    'imageUrl':
        'https://img.rocket.new/generatedImages/rocket_gen_img_1de0109c5-1772378332978.png',
    'semanticLabel':
        'Traditional South Indian filter coffee served in steel tumbler and dabara with frothy top',
    'tag': '☕ Fresh',
    'originalPrice': null,
  },
];

class HomeFoodGridWidget extends StatefulWidget {
  final bool isLoading;
  final String selectedCategory;
  final Map<String, int> cartItems;
  final bool isTablet;
  final Function(String) onAddToCart;
  final Function(String) onRemoveFromCart;

  const HomeFoodGridWidget({
    super.key,
    required this.isLoading,
    required this.selectedCategory,
    required this.cartItems,
    required this.isTablet,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  @override
  State<HomeFoodGridWidget> createState() => _HomeFoodGridWidgetState();
}

class _HomeFoodGridWidgetState extends State<HomeFoodGridWidget> {
  List<DishModel> _dishes = [];

  @override
  void initState() {
    super.initState();
    _dishes = _dishMaps.map(DishModel.fromMap).toList();
  }

  List<DishModel> get _filteredDishes {
    if (widget.selectedCategory == 'All') return _dishes;
    return _dishes.where((d) => d.category == widget.selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.isTablet ? 3 : 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => const FoodCardSkeletonWidget(),
          childCount: 6,
        ),
      );
    }

    final dishes = _filteredDishes;
    if (dishes.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  'No dishes in this category',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Try selecting a different category',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.isTablet ? 3 : 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return _FoodCardWidget(
          dish: dishes[index],
          cartCount: widget.cartItems[dishes[index].id] ?? 0,
          onAdd: () => widget.onAddToCart(dishes[index].id),
          onRemove: () => widget.onRemoveFromCart(dishes[index].id),
        );
      }, childCount: dishes.length),
    );
  }
}

class _FoodCardWidget extends StatefulWidget {
  final DishModel dish;
  final int cartCount;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _FoodCardWidget({
    required this.dish,
    required this.cartCount,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_FoodCardWidget> createState() => _FoodCardWidgetState();
}

class _FoodCardWidgetState extends State<_FoodCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.88,
          end: 1.06,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.06,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleAddToCart() {
    if (!widget.dish.isAvailable) return;
    HapticFeedback.lightImpact();
    _bounceController.forward(from: 0);
    widget.onAdd();
  }

  @override
  Widget build(BuildContext context) {
    final dish = widget.dish;
    final hasInCart = widget.cartCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: hasInCart
            ? Border.all(color: AppTheme.primary.withAlpha(77), width: 1.5)
            : Border.all(color: const Color(0xFFEFF7F1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: ColorFiltered(
                  colorFilter: dish.isAvailable
                      ? const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.saturation,
                        )
                      : const ColorFilter.matrix([
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                  child: CustomImageWidget(
                    imageUrl: dish.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: dish.semanticLabel,
                  ),
                ),
              ),
              // Veg/Non-veg indicator
              Positioned(
                top: 8,
                left: 8,
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
              // Tag badge
              if (dish.tag.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: dish.isAvailable
                          ? AppTheme.primary
                          : Colors.grey[600],
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
              // Chef Special badge
              if (dish.isChefSpecial && dish.isAvailable)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withAlpha(0),
                          Colors.black.withAlpha(140),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 10,
                          color: Color(0xFFFFB347),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "Chef's Special",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!dish.isAvailable)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(89),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Currently Unavailable',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppTheme.ratingGold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${dish.rating}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        ' (${dish.reviewCount})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        dish.prepTime,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                        ],
                      ),
                      const Spacer(),
                      if (!dish.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'N/A',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        )
                      else if (hasInCart)
                        _CartQuantityWidget(
                          count: widget.cartCount,
                          onAdd: _handleAddToCart,
                          onRemove: widget.onRemove,
                        )
                      else
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: GestureDetector(
                            onTap: _handleAddToCart,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: AppTheme.buttonShadow,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
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

class _CartQuantityWidget extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartQuantityWidget({
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const SizedBox(
              width: 28,
              height: 32,
              child: Icon(Icons.remove_rounded, color: Colors.white, size: 14),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '$count',
              key: ValueKey(count),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const SizedBox(
              width: 28,
              height: 32,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
