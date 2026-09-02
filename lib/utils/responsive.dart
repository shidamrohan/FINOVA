import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double fontSize(BuildContext context, double size) {
    double screenWidth = width(context);
    // Base width: 375 (iPhone SE/8)
    return size * (screenWidth / 375);
  }

  static double sp(BuildContext context, double size) {
    return fontSize(context, size);
  }

  static double hp(BuildContext context, double percentage) {
    return height(context) * (percentage / 100);
  }

  static double wp(BuildContext context, double percentage) {
    return width(context) * (percentage / 100);
  }

  static bool isMobile(BuildContext context) {
    return width(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    return width(context) >= 600 && width(context) < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return width(context) >= 1024;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: wp(context, 4),
      vertical: hp(context, 2),
    );
  }

  static double cardPadding(BuildContext context) {
    return wp(context, 4);
  }

  static double borderRadius(BuildContext context, double size) {
    return wp(context, size / 10);
  }
}