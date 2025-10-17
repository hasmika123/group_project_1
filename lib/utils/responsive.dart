import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  /// Determine device type using width breakpoints.
  static DeviceType deviceType(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return DeviceType.desktop;
    if (w >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Provide consistent padding depending on device size
  static EdgeInsets pagePadding(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    }
  }

  /// Scale a base font size based on device type.
  static double fontSize(BuildContext context, double base) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return base * 1.25;
      case DeviceType.tablet:
        return base * 1.1;
      case DeviceType.mobile:
        return base;
    }
  }

  /// Choose whether to lay out content horizontally (row) or vertically (column)
  /// for summary cards and similar compact content.
  static bool useHorizontalLayout(BuildContext context) {
    return deviceType(context) != DeviceType.mobile;
  }
}
