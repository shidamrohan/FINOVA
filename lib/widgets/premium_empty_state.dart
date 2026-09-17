import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/responsive.dart';

class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.wp(context, 8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: EdgeInsets.all(Responsive.wp(context, 8)),
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: Responsive.sp(context, 80),
                      color: iconColor ?? AppTheme.primary,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: Responsive.hp(context, 3)),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.sp(context, 22),
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: Responsive.hp(context, 1.5)),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: Responsive.sp(context, 15),
                color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: Responsive.hp(context, 4)),

              // Button
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: ElevatedButton(
                      onPressed: onButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.wp(context, 8),
                          vertical: Responsive.hp(context, 2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.borderRadius(context, 16),
                          ),
                        ),
                        elevation: 5,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: Responsive.sp(context, 20)),
                          SizedBox(width: Responsive.wp(context, 2)),
                          Text(
                            buttonText!,
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
