import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;
  late double screenWidth;
  late double screenHeight;
  late double textScaleFactor;

  // Reference dimensions (iPhone 11 Pro)
  static const double referenceWidth = 375.0;
  static const double referenceHeight = 812.0;

  ResponsiveHelper(this.context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    textScaleFactor = mediaQuery.textScaleFactor;
  }

  // Width percentage helper
  double wp(double percentage) => screenWidth * (percentage / 100);

  // Height percentage helper
  double hp(double percentage) => screenHeight * (percentage / 100);

  // Responsive width based on reference
  double w(double size) => screenWidth * (size / referenceWidth);

  // Responsive height based on reference
  double h(double size) => screenHeight * (size / referenceHeight);

  // Responsive font size
  double fs(double size) => w(size) * textScaleFactor;

  // Check if tablet (width > 600)
  bool isTablet() => screenWidth > 600;

  // Check if phone
  bool isPhone() => screenWidth <= 600;

  // Scale factor for width
  double get scaleWidth => screenWidth / referenceWidth;

  // Scale factor for height
  double get scaleHeight => screenHeight / referenceHeight;
}
