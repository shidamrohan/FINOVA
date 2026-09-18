import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/category_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/slide_animation.dart';
import '../../widgets/premium_empty_state.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(Responsive.wp(context, 2)),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
              size: Responsive.sp(context, 20),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.wp(context, 2)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF00D4AA)],
                ),
                borderRadius:
                    BorderRadius.circular(Responsive.borderRadius(context, 10)),
              ),
              child: Icon(
                Icons.category,
                color: Colors.white,
                size: Responsive.sp(context, 18),
              ),
            ),
            SizedBox(width: Responsive.wp(context, 2)),
            Text(
              'Manage Categories',
              style: TextStyle(
                color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                fontSize: Responsive.sp(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<CategoryProvider>(
          builder: (context, categoryProvider, _) {
            final categories = categoryProvider.categories;

            if (categories.isEmpty) {
              return PremiumEmptyState(
                icon: Icons.category_outlined,
                title: 'No Categories Yet',
                subtitle:
                    'Create custom categories to organize\nyour expenses efficiently',
                buttonText: 'Create Category',
                onButtonPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditCategoryScreen(),
                    ),
                  );
                },
                iconColor: AppTheme.primary,
              );
            }

            return Column(
              children: [
                // Info Banner
                SlideInAnimation(
                  delay: 0,
                  child: Padding(
                    padding: EdgeInsets.all(Responsive.wp(context, 4)),
                    child: PremiumCard(
                      padding: EdgeInsets.all(Responsive.wp(context, 4)),
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      enableShadow: false,
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Responsive.wp(context, 2)),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                Responsive.borderRadius(context, 10),
                              ),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppTheme.primary,
                              size: Responsive.sp(context, 18),
                            ),
                          ),
                          SizedBox(width: Responsive.wp(context, 3)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Tip',
                                  style: TextStyle(
                                    fontSize: Responsive.sp(context, 12),
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                SizedBox(height: Responsive.hp(context, 0.3)),
                                Text(
                                  'Tap to edit • Long press to delete',
                                  style: TextStyle(
                                    fontSize: Responsive.sp(context, 11),
                                    color: AppTheme.primary.withValues(alpha: 0.8),
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

                // Categories List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.wp(context, 4),
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return SlideInAnimation(
                        delay: 100 + (index * 50),
                        child: _buildCategoryCard(
                          context,
                          isDark,
                          categories[index],
                          categoryProvider,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditCategoryScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        elevation: 8,
        icon: Icon(
          Icons.add,
          color: Colors.white,
          size: Responsive.sp(context, 24),
        ),
        label: Text(
          'Add Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.sp(context, 15),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    bool isDark,
    dynamic category,
    CategoryProvider categoryProvider,
  ) {
    return AnimatedCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditCategoryScreen(category: category),
          ),
        );
      },
      margin: EdgeInsets.only(bottom: Responsive.hp(context, 1.5)),
      child: InkWell(
        onLongPress: () {
          _showDeleteDialog(context, category, categoryProvider, isDark);
        },
        borderRadius:
            BorderRadius.circular(Responsive.borderRadius(context, 20)),
        child: Padding(
          padding: EdgeInsets.all(Responsive.wp(context, 4)),
          child: Row(
            children: [
              // Icon with Gradient Background
              Container(
                padding: EdgeInsets.all(Responsive.wp(context, 4)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(category.colorValue).withValues(alpha: 0.25),
                      Color(category.colorValue).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    Responsive.borderRadius(context, 16),
                  ),
                  border: Border.all(
                    color: Color(category.colorValue).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(category.colorValue).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: Color(category.colorValue),
                  size: Responsive.sp(context, 30),
                ),
              ),

              SizedBox(width: Responsive.wp(context, 4)),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 17),
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppTheme.textDark : AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.hp(context, 0.5)),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.wp(context, 2),
                            vertical: Responsive.hp(context, 0.3),
                          ),
                          decoration: BoxDecoration(
                            color: Color(category.colorValue).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: Responsive.wp(context, 2),
                                height: Responsive.wp(context, 2),
                                decoration: BoxDecoration(
                                  color: Color(category.colorValue),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: Responsive.wp(context, 1)),
                              Text(
                                'Custom Color',
                                style: TextStyle(
                                  fontSize: Responsive.sp(context, 10),
                                  fontWeight: FontWeight.w600,
                                  color: Color(category.colorValue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Indicators
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(Responsive.wp(context, 2)),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: AppTheme.primary,
                      size: Responsive.sp(context, 16),
                    ),
                  ),
                  SizedBox(height: Responsive.hp(context, 0.5)),
                  Icon(
                    Icons.drag_indicator,
                    color:
                        isDark ? AppTheme.textMutedDark : Colors.grey.shade400,
                    size: Responsive.sp(context, 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    dynamic category,
    CategoryProvider categoryProvider,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Responsive.borderRadius(context, 20)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.wp(context, 2)),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline,
                color: AppTheme.danger,
                size: Responsive.sp(context, 24),
              ),
            ),
            SizedBox(width: Responsive.wp(context, 3)),
            Flexible(
              child: Text(
                'Delete Category',
                style: TextStyle(
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  fontSize: Responsive.sp(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\nThis action cannot be undone.',
          style: TextStyle(
            color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
            fontSize: Responsive.sp(context, 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await categoryProvider.addCategory(category);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: Responsive.wp(context, 2)),
                        Text('${category.name} deleted successfully'),
                      ],
                    ),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
