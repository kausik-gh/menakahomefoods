import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class AdminMenuTab extends StatefulWidget {
  const AdminMenuTab({super.key});

  @override
  State<AdminMenuTab> createState() => _AdminMenuTabState();
}

class _AdminMenuTabState extends State<AdminMenuTab> {
  final List<String> _categories = ['All', 'Breakfast', 'Lunch', 'Dinner'];
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _loading = true);
    final rows = await SupabaseService.instance.getMenuItems();
    if (!mounted) return;
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    final meal = _selectedCategory.toLowerCase();
    return _items
        .where(
          (item) =>
              ((item['meal_type'] as String?) ?? '').toLowerCase() == meal,
        )
        .toList();
  }

  Future<void> _toggleAvailability(String itemId, bool currentValue) async {
    try {
      await SupabaseService.instance.client
          .from('menu_items')
          .update({'available_today': !currentValue})
          .eq('id', itemId);
      await _loadMenu();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update availability', AppTheme.error);
    }
  }

  Future<void> _showEditModal({Map<String, dynamic>? item}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _EditDishDialog(item: item),
    );

    if (saved == true) {
      await _loadMenu();
      if (!mounted) return;
      _showMessage('Menu item saved', AppTheme.success);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditModal(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Dish',
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
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : RefreshIndicator(
                  onRefresh: _loadMenu,
                  color: AppTheme.primary,
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.restaurant_menu_rounded,
                                size: 48,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No dishes in this category',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) =>
                              _buildDishCard(_filteredItems[index]),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildDishCard(Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    final isVeg = item['is_veg'] as bool? ?? true;
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final availableToday = item['available_today'] as bool? ?? true;
    final mealType = ((item['meal_type'] as String?) ?? 'breakfast')
        .toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: _MenuItemImage(
                  imageUrl: (item['image_url'] as String?)?.trim(),
                  semanticLabel: item['name'] as String? ?? 'Menu item',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isVeg
                                ? AppTheme.vegGreen
                                : AppTheme.nonVegRed,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isVeg
                                  ? AppTheme.vegGreen
                                  : AppTheme.nonVegRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item['name'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['description'] as String? ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _mealLabel(mealType),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                GestureDetector(
                  onTap: () => _showEditModal(item: item),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _toggleAvailability(itemId, availableToday),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: availableToday
                          ? AppTheme.successLight
                          : AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      availableToday ? 'Live' : 'Hidden',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: availableToday
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDishDialog extends StatefulWidget {
  final Map<String, dynamic>? item;

  const _EditDishDialog({this.item});

  @override
  State<_EditDishDialog> createState() => _EditDishDialogState();
}

class _EditDishDialogState extends State<_EditDishDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _selectedContentType;
  String? _imageUrl;
  String _mealType = 'breakfast';
  bool _isVeg = true;
  bool _availableToday = true;
  bool _saving = false;
  bool _imageExpanded = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl.text = item?['name'] as String? ?? '';
    _descCtrl.text = item?['description'] as String? ?? '';
    _priceCtrl.text = item != null
        ? (item['price'] as num?)?.toString() ?? ''
        : '';
    _mealType = ((item?['meal_type'] as String?) ?? 'breakfast').toLowerCase();
    _isVeg = item?['is_veg'] as bool? ?? true;
    _availableToday = item?['available_today'] as bool? ?? true;
    _imageUrl = (item?['image_url'] as String?)?.trim();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = image.name;
      _selectedContentType = image.mimeType;
      _imageExpanded = false;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty || price == null) {
      _showInlineMessage('Enter a valid name and price', AppTheme.error);
      return;
    }

    setState(() => _saving = true);

    try {
      final baseData = <String, dynamic>{
        'name': name,
        'description': _descCtrl.text.trim(),
        'price': price,
        'meal_type': _mealType,
        'category': _mealLabel(_mealType),
        'is_veg': _isVeg,
        'available_today': _availableToday,
      };

      String itemId;
      final existingId = widget.item?['id'] as String?;

      if (existingId == null) {
        final inserted = await SupabaseService.instance.client
            .from('menu_items')
            .insert({
              ...baseData,
              'image_url': null,
              'available_for_order': true,
              'available_for_subscription': true,
            })
            .select('id')
            .single();
        itemId = inserted['id'] as String;
      } else {
        itemId = existingId;
      }

      String? uploadedImageUrl = _imageUrl;
      if (_selectedImageBytes != null && _selectedImageName != null) {
        uploadedImageUrl = await SupabaseService.instance.uploadMenuItemImage(
          itemId: itemId,
          bytes: _selectedImageBytes!,
          originalFileName: _selectedImageName!,
          contentType: _selectedContentType,
        );
      }

      final payload = {
        ...baseData,
        'image_url': uploadedImageUrl == null || uploadedImageUrl.trim().isEmpty
            ? null
            : uploadedImageUrl.trim(),
      };

      await SupabaseService.instance.client
          .from('menu_items')
          .update(payload)
          .eq('id', itemId);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      _showInlineMessage('Could not save this menu item', AppTheme.error);
      setState(() => _saving = false);
    }
  }

  void _showInlineMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _collapseImage() {
    if (_imageExpanded) {
      setState(() => _imageExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width < 720
        ? MediaQuery.of(context).size.width - 32
        : 540.0;

    return GestureDetector(
      onTap: _collapseImage,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _collapseImage();
          },
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item == null ? 'Add Dish' : 'Edit Dish',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Name'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameCtrl,
                          hintText: 'Menu item name',
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 14),
                        _buildLabel('Description'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _descCtrl,
                          hintText: 'Short description',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Price'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _priceCtrl,
                                    hintText: '0.00',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Meal type'),
                                  const SizedBox(height: 8),
                                  _buildDropdown(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _ToggleCard(
                                label: 'Vegetarian',
                                value: _isVeg,
                                activeColor: AppTheme.vegGreen,
                                onChanged: (value) => setState(() {
                                  _isVeg = value;
                                  _imageExpanded = false;
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ToggleCard(
                                label: 'Available',
                                value: _availableToday,
                                activeColor: AppTheme.primary,
                                onChanged: (value) => setState(() {
                                  _availableToday = value;
                                  _imageExpanded = false;
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Image'),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImagePreview(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.upload_rounded,
                                            size: 16,
                                            color: AppTheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Upload image',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedImageName ??
                                        ((_imageUrl == null ||
                                                _imageUrl!.trim().isEmpty)
                                            ? 'No image selected'
                                            : 'Current image'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(color: AppTheme.surfaceVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: AppTheme.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.surfaceVariant.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onTap: _collapseImage,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _mealType,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.surfaceVariant.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: const ['breakfast', 'lunch', 'dinner']
          .map(
            (meal) => DropdownMenuItem<String>(
              value: meal,
              child: Text(
                _mealLabel(meal),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _mealType = value;
          _imageExpanded = false;
        });
      },
    );
  }

  Widget _buildImagePreview() {
    final hasImage =
        _selectedImageBytes != null || (_imageUrl?.isNotEmpty ?? false);
    final size = _imageExpanded ? 220.0 : 84.0;

    return GestureDetector(
      onTap: hasImage
          ? () => setState(() => _imageExpanded = !_imageExpanded)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE1E5EA),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImageBytes != null
            ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
            : (_imageUrl == null || _imageUrl!.isEmpty)
            ? const SizedBox.shrink()
            : CustomImageWidget(
                imageUrl: _imageUrl,
                fit: BoxFit.cover,
                errorWidget: Container(color: const Color(0xFFE1E5EA)),
              ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: activeColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemImage extends StatelessWidget {
  final String? imageUrl;
  final String semanticLabel;

  const _MenuItemImage({required this.imageUrl, required this.semanticLabel});

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

String _mealLabel(String mealType) {
  switch (mealType) {
    case 'breakfast':
      return 'Breakfast';
    case 'lunch':
      return 'Lunch';
    case 'dinner':
      return 'Dinner';
    default:
      return 'Breakfast';
  }
}
