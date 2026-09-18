import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../utils/responsive.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Color _selectedColor = const Color(0xFFFF3B30);
  IconData _selectedIcon = Icons.shopping_bag;

  final List<Color> _colors = [
    const Color(0xFFFF3B30), // Red
    const Color(0xFFFF9500), // Orange
    const Color(0xFFFFCC00), // Yellow
    const Color(0xFF34C759), // Green
    const Color(0xFF00C7BE), // Teal
    const Color(0xFF32ADE6), // Light Blue
    const Color(0xFF007AFF), // Blue
    const Color(0xFF5856D6), // Purple
    const Color(0xFFAF52DE), // Purple2
    const Color(0xFFFF2D55), // Pink
  ];

  final List<IconData> _icons = [
    Icons.shopping_bag,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_grocery_store,
    Icons.directions_car,
    Icons.local_gas_station,
    Icons.home,
    Icons.lightbulb,
    Icons.phone_android,
    Icons.laptop,
    Icons.headphones,
    Icons.fitness_center,
    Icons.medical_services,
    Icons.school,
    Icons.book,
    Icons.theaters,
    Icons.flight,
    Icons.hotel,
    Icons.beach_access,
    Icons.pets,
    Icons.child_care,
    Icons.shopping_cart,
    Icons.credit_card,
    Icons.attach_money,
    Icons.trending_up,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedColor = Color(widget.category!.colorValue);
      _selectedIcon =
          IconData(widget.category!.iconCodePoint, fontFamily: 'MaterialIcons');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.category != null;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Category' : 'Add Category',
          style: TextStyle(
            color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
            fontSize: Responsive.sp(context, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveCategory,
            child: Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: Responsive.sp(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.wp(context, 4)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview
                Center(
                  child: Container(
                    padding: EdgeInsets.all(Responsive.wp(context, 8)),
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedIcon,
                      color: _selectedColor,
                      size: Responsive.sp(context, 60),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.hp(context, 3)),

                // Name Field
                Text(
                  'Category Name',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 16),
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: Responsive.hp(context, 1)),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 16),
                    color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., Shopping, Food, Transport',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppTheme.textMutedDark
                          : AppTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor:
                        isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          Responsive.borderRadius(context, 12)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Responsive.wp(context, 4),
                      vertical: Responsive.hp(context, 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a category name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: Responsive.hp(context, 3)),

                // Color Picker
                Text(
                  'Choose Color',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 16),
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: Responsive.hp(context, 1.5)),
                Wrap(
                  spacing: Responsive.wp(context, 3),
                  runSpacing: Responsive.hp(context, 1.5),
                  children: _colors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: Responsive.wp(context, 14),
                        height: Responsive.wp(context, 14),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: Responsive.sp(context, 24),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: Responsive.hp(context, 3)),

                // Icon Picker
                Text(
                  'Choose Icon',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 16),
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: Responsive.hp(context, 1.5)),
                Container(
                  padding: EdgeInsets.all(Responsive.wp(context, 2)),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(
                        Responsive.borderRadius(context, 12)),
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: Responsive.wp(context, 2),
                      mainAxisSpacing: Responsive.hp(context, 1),
                    ),
                    itemCount: _icons.length,
                    itemBuilder: (context, index) {
                      final icon = _icons[index];
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = icon;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _selectedColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                                Responsive.borderRadius(context, 8)),
                            border: Border.all(
                              color: isSelected
                                  ? _selectedColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? _selectedColor
                                : (isDark
                                    ? AppTheme.textMutedDark
                                    : Colors.grey.shade600),
                            size: Responsive.sp(context, 28),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);

      final category = Category(
        id: widget.category?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        iconCodePoint: _selectedIcon.codePoint,
        colorValue: _selectedColor.value,
      );

      if (widget.category != null) {
        await categoryProvider.addCategory(category);
      } else {
        await categoryProvider.addCategory(category);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category != null
                  ? 'Category updated!'
                  : 'Category created!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }
}
